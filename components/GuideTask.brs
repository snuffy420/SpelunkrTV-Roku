sub init()
    m.top.functionName = "loadSpelunkrGuide"
end sub

sub loadSpelunkrGuide()
    publishCharWidths()
    base = "https://data.spelunkr.tv/"
    m.top.status = "Loading live lineup..."
    lineup = spelunkrJson(base + "lineup.json")
    if type(lineup) <> "roAssociativeArray"
        m.top.status = "Could not load the live lineup. Press Options to retry."
        m.top.complete = true
        return
    end if
    if type(lineup.channels) <> "roArray"
        m.top.status = "Could not load the live lineup. Press Options to retry."
        m.top.complete = true
        return
    end if

    nowSec = CreateObject("roDateTime").AsSeconds()
    output = []
    ' Keep the guide aligned with the public directory. The upstream lineup
    ' also contains internal/test feeds that are intentionally not listed there.
    directoryIds = ["saturday-morning", "primetime", "syndicate", "late-nite-local", "happy-trees", "computer-chronicles", "open-mic", "library-card", "nature-preserve", "unpaid-programming", "radio-active-tv", "orange-soda", "latchkey-tv", "kersplat", "final-frontier", "rocket-punch", "ovatv", "toonertia", "late-nite-swimclub", "warp-zone", "homeroom", "mandatory-viewing", "fallout-shelter", "dusty-trails", "gumshoe", "it-came-from", "daily-dread", "graveyard-shift", "ray-gun", "signpost", "waku-waku", "rubber-hose", "meddling-kids", "suplex", "vacation-slides"]
    for each channel in lineup.channels
        if not spelunkrIsDirectoryChannel(channel.id, directoryIds) then continue for
        dial = spelunkrText(channel.dial)
        if Len(dial) = 1 then dial = "0" + dial
        ' Only what the guide draws crosses to the render thread. Logos ship as
        ' PNGs in the package (tools/build_assets.py), so their pixel rows do not.
        ' The directory screen mirrors spelunkr.tv/directory: the REWIND tag comes
        ' from family, and "N TAPES · N HRS" from stats (hours rounded, as the site does).
        statsText = ""
        if type(channel.stats) = "roAssociativeArray"
            hoursRounded = Int(spelunkrWhole(channel.stats.videoSeconds) / 3600 + 0.5)
            statsText = spelunkrWhole(channel.stats.items).ToStr() + " TAPES · " + hoursRounded.ToStr() + " HRS"
        end if
        familyText = ""
        if LCase(spelunkrText(channel.family)) = "rewind" then familyText = "REWIND"
        output.Push({id: channel.id, name: channel.name, description: spelunkrText(channel.description), family: familyText, stats: statsText, dial: dial, color: channel.color, logoUri: "pkg:/images/logos/" + channel.id + ".png", schedule: spelunkrCurrentVersion(channel.versions, nowSec), timeline: [], timelineLoaded: false, timelineEndSec: 0, nowIndex: 0, now: invalid, next: invalid, elapsed: 0, descriptions: {}})
    end for
    m.top.channels = output
    m.top.status = "Live lineup · " + output.Count().ToStr() + " channels"
    m.top.complete = true
end sub

' Font metrics are only available off the render thread, so the scene gets a
' table of character widths in the system font at size 22, keyed by code point.
sub publishCharWidths()
    try
        font = CreateObject("roFontRegistry").GetDefaultFont(22, false, false)
        if font = invalid then return
        widths = {}
        codes = [183, 233, 8211, 8212, 8216, 8217, 8220, 8221, 8230]
        for code = 32 to 126
            codes.Push(code)
        end for
        for each code in codes
            widths[code.ToStr()] = font.GetOneLineWidth(Chr(code), 1000)
        end for
        m.top.charWidths = widths
    catch problem
        print "Character widths unavailable: "; problem.message
    end try
end sub

function spelunkrIsDirectoryChannel(channelId as Dynamic, directoryIds as Object) as Boolean
    if type(channelId) <> "String" and type(channelId) <> "roString" then return false
    for each directoryId in directoryIds
        if channelId = directoryId then return true
    end for
    return false
end function

' One long-lived worker replaces a new Task per page. A burst of page jumps now
' reorders a single queue instead of stacking threads, downloads and JSON parses.
sub runScheduleWorker()
    m.base = "https://data.spelunkr.tv/"
    m.port = CreateObject("roMessagePort")
    m.queue = []
    m.inFlight = {}
    m.platforms = {}
    m.elapsedTimer = CreateObject("roTimespan")
    m.nextBackgroundMs = 0
    m.loadedCount = 0
    m.cachedCount = 0
    m.outbox = []
    m.top.ObserveField("scheduleQueue", m.port)
    ' The scene may have queued its first request before this thread got here.
    workerReplaceQueue(m.top.scheduleQueue)
    ' One bad request must never end listing updates for the whole app, so each
    ' turn of the loop catches and logs its own errors.
    while true
        try
            workerStartRequests()
            message = Wait(250, m.port)
            if type(message) = "roSGNodeEvent"
                workerReplaceQueue(message.GetData())
            else if type(message) = "roUrlEvent"
                workerHandleResponse(message)
            end if
            workerExpireRequests()
            workerFlush()
        catch problem
            print "Listings worker error: "; problem.message
            ' Drop the request that failed so the queue keeps moving.
            if m.queue.Count() > 0 then m.queue.Shift()
        end try
    end while
end sub

sub workerReplaceQueue(entries as Dynamic)
    if type(entries) <> "roArray" then return
    ' Drop downloads the user has moved away from so the new page goes first.
    for each key in m.inFlight.Keys()
        keep = m.inFlight[key].entry.kind <> "manifest"
        if not keep
            for each entry in entries
                if entry.priority and entry.id = m.inFlight[key].entry.id
                    keep = true
                    exit for
                end if
            end for
        end if
        if not keep
            m.inFlight[key].transfer.AsyncCancel()
            m.inFlight.Delete(key)
        end if
    end for
    ' Descriptions and server lookups already waiting stay queued: they are not
    ' part of the request.
    waitingDetails = []
    for each entry in m.queue
        if entry.kind <> "manifest" then waitingDetails.Push(entry)
    end for
    m.queue = []
    for each entry in entries
        if not workerIsInFlight(entry.id) then m.queue.Push(entry)
    end for
    m.queue.Append(waitingDetails)
end sub

function workerIsInFlight(channelId as String) as Boolean
    for each key in m.inFlight
        request = m.inFlight[key]
        if request.entry.kind = "manifest" and request.entry.id = channelId then return true
    end for
    return false
end function

sub workerStartRequests()
    while m.queue.Count() > 0
        entry = m.queue[0]
        ' Listings already built on an earlier launch need no network at all.
        ' The request comes off the queue first: answering it from the cache
        ' queues more work (descriptions, server lookups) at the front, and
        ' removing it afterwards took one of those instead, so the request was
        ' answered again and again and nothing ever reached the screen.
        if entry.kind = "manifest" or entry.kind = "details"
            m.queue.Shift()
            if entry.kind = "manifest" then hit = workerUseCachedSchedule(entry) else hit = workerUseCachedDetails(entry)
            if hit then continue while
            m.queue.Unshift(entry)
        end if
        ' Downloads overlap with building the previous channel's listings; the
        ' background still leaves room for the video and the remote.
        limit = 2
        if entry.priority then limit = 4
        if m.inFlight.Count() >= limit then return
        if not entry.priority and m.elapsedTimer.TotalMilliseconds() < m.nextBackgroundMs then return
        m.queue.Shift()
        url = entry.manifest
        if Left(url, 8) <> "https://" then url = m.base + url
        transfer = spelunkrTransfer(url)
        transfer.SetMessagePort(m.port)
        if transfer.AsyncGetToString()
            m.inFlight[transfer.GetIdentity().ToStr()] = {transfer: transfer, entry: entry, startedMs: m.elapsedTimer.TotalMilliseconds()}
        else
            workerEmit({id: entry.id, ok: false})
        end if
    end while
end sub

sub workerHandleResponse(event as Object)
    key = event.GetSourceIdentity().ToStr()
    if not m.inFlight.DoesExist(key) then return
    entry = m.inFlight[key].entry
    m.inFlight.Delete(key)
    succeeded = event.GetInt() = 1 and event.GetResponseCode() >= 200 and event.GetResponseCode() < 300
    if entry.kind = "details"
        if succeeded
            text = event.GetString()
            workerPublishDescriptions(entry, ParseJson(text))
            WriteAsciiFile(workerCachePath("details", entry.manifest), text)
        end if
    else if entry.kind = "resolve"
        if succeeded then workerResolveStep(entry, ParseJson(event.GetString()))
    else
        result = invalid
        if succeeded
            manifest = ParseJson(event.GetString())
            if type(manifest) = "roAssociativeArray"
                if type(manifest.items) = "roArray"
                    now = CreateObject("roDateTime")
                    nowSec = now.AsSeconds()
                    now.ToLocalTime()
                    hourStartSec = nowSec - now.GetMinutes() * 60 - now.GetSeconds()
                    windowEndSec = hourStartSec + 21600
                    ' From an hour before this hour: the guide shows half an hour of
                    ' past and REW can look back to the start of the previous hour.
                    windowStartSec = hourStartSec - 3600
                    ' A delayed viewer needs listings from before this hour (up to a day).
                    if entry.fromSec <> invalid
                        if entry.fromSec < windowStartSec and entry.fromSec > nowSec - 90000 then windowStartSec = entry.fromSec
                    end if
                    result = workerBuildSchedule(manifest, entry, nowSec, windowStartSec, windowEndSec)
                end if
            end if
        end if
        if result = invalid then result = {id: entry.id, ok: false}
        workerEmit(result)
        if result.ok
            if entry.fromSec = invalid then workerSaveSchedule(entry, result, windowStartSec, windowEndSec)
            workerQueueDetails(entry, result.events)
            workerQueueResolves(entry, result.events)
            workerCountLoaded(false)
        end if
    end if
    m.nextBackgroundMs = m.elapsedTimer.TotalMilliseconds() + 150
end sub

' Results go to the scene in one batch per pass of the worker loop. Setting a
' field many times in a row from this thread loses all but the last value on
' the render thread, which is how 34 of 35 cached channels went missing.
sub workerEmit(result as Object)
    m.outbox.Push(result)
end sub

sub workerFlush()
    if m.outbox.Count() = 0 then return
    ' Batches at least 100 ms apart, so two in quick succession cannot merge
    ' either; what waits goes in the next pass (the loop wakes every 250 ms).
    nowMs = m.elapsedTimer.TotalMilliseconds()
    if m.lastFlushMs <> invalid
        if nowMs - m.lastFlushMs < 100 then return
    end if
    m.lastFlushMs = nowMs
    m.top.scheduleBatch = m.outbox
    m.outbox = []
end sub

' ---- Listings cache ------------------------------------------------------------
' Built listings are kept in cachefs: per channel, the schedule version they
' came from and the window they cover. A relaunch within about an hour and a
' half reuses them with no download, parse or broadcast replay. Program
' descriptions are kept by their versioned file name.

function workerCachePath(kind as String, key as Dynamic) as String
    if type(key) <> "String" and type(key) <> "roString" then return "cachefs:/spelunkr-none.json"
    safe = key.Replace("/", "_").Replace(":", "_")
    return "cachefs:/spelunkr-" + kind + "-" + safe + ".json"
end function

' Reads a cache file, or "" when there is none (checked first, so a miss does
' not print a firmware error for every channel).
function workerReadCache(path as String) as String
    if m.fileSystem = invalid then m.fileSystem = CreateObject("roFileSystem")
    if not m.fileSystem.Exists(path) then return ""
    return ReadAsciiFile(path)
end function

function workerUseCachedSchedule(entry as Object) as Boolean
    if entry.fromSec <> invalid then return false
    text = workerReadCache(workerCachePath("sched", entry.id))
    if text = "" then return false
    cached = ParseJson(text)
    if type(cached) <> "roAssociativeArray" then return false
    if cached.version <> entry.version or cached.epochSec <> entry.epochSec or cached.startIndex <> entry.startIndex then return false
    now = CreateObject("roDateTime")
    nowSec = now.AsSeconds()
    now.ToLocalTime()
    hourStartSec = nowSec - now.GetMinutes() * 60 - now.GetSeconds()
    ' Must cover the half hour of past on screen and four and a half hours ahead.
    if cached.windowStartSec > nowSec - 2400 or cached.windowEndSec < hourStartSec + 16200 then return false
    result = cached.result
    if type(result) <> "roAssociativeArray" or type(result.events) <> "roArray" then return false
    workerEmit(result)
    workerQueueDetails(entry, result.events)
    workerQueueResolves(entry, result.events)
    workerCountLoaded(true)
    ' Shown from cache at once, then rebuilt from the live data in the
    ' background, which also saves a fresh copy for next time.
    ' Once per channel per launch; after that, the hourly updates rebuild it
    ' whenever the cached window runs short.
    if m.refreshQueued = invalid then m.refreshQueued = {}
    if not m.refreshQueued.DoesExist(entry.id)
        m.refreshQueued[entry.id] = true
        refresh = {}
        refresh.Append(entry)
        refresh.kind = "refresh"
        refresh.priority = false
        m.queue.Push(refresh)
    end if
    return true
end function

sub workerSaveSchedule(entry as Object, result as Object, windowStartSec as Integer, windowEndSec as Integer)
    cached = {version: entry.version, epochSec: entry.epochSec, startIndex: entry.startIndex, windowStartSec: windowStartSec, windowEndSec: windowEndSec, result: result}
    WriteAsciiFile(workerCachePath("sched", entry.id), FormatJson(cached))
end sub

function workerUseCachedDetails(entry as Object) as Boolean
    text = workerReadCache(workerCachePath("details", entry.manifest))
    if text = "" then return false
    details = ParseJson(text)
    if type(details) <> "roAssociativeArray" then return false
    workerPublishDescriptions(entry, details)
    return true
end function

' One line in the log once every channel has listings, to measure load time.
sub workerCountLoaded(fromCache as Boolean)
    m.loadedCount = m.loadedCount + 1
    if fromCache then m.cachedCount = m.cachedCount + 1
    if m.loadedCount = m.top.channelCount
        print "All listings loaded: "; m.loadedCount; " channels in "; m.elapsedTimer.TotalMilliseconds(); " ms ("; m.cachedCount; " from cache)"
    end if
end sub

' Website timing first. A failure in it must never cost the channel its listings,
' and an error in this thread would otherwise silently end all listing updates.
function workerBuildSchedule(manifest as Object, entry as Object, nowSec as Integer, windowStartSec as Integer, windowEndSec as Integer) as Dynamic
    result = invalid
    try
        if entry.epochSec <= nowSec then result = spelunkrBroadcast(manifest, workerPlatform(manifest.platform), entry, windowStartSec, windowEndSec)
    catch problem
        print "Broadcast timing failed for "; entry.id; ": "; problem.message
        result = invalid
    end try
    if result = invalid then result = spelunkrBuildSchedule(manifest.items, entry, nowSec, windowStartSec, windowEndSec)
    return result
end function

' The bumper list shared by every channel. It lives in one small file, fetched once.
function workerPlatform(path as Dynamic) as Dynamic
    if path = invalid then return invalid
    if m.platforms.DoesExist(path) then return m.platforms[path]
    platform = spelunkrJson(m.base + path)
    if type(platform) <> "roAssociativeArray" then return invalid
    platform = {bumps: platform.bumps}
    m.platforms[path] = platform
    return platform
end function

sub workerQueueDetails(entry as Object, events as Object)
    if entry.details = invalid or entry.details = "" then return
    indices = []
    for each event in events
        if event.kind = "video" then indices.Push(event.index)
    end for
    if indices.Count() = 0 then return
    request = {kind: "details", id: entry.id, manifest: entry.details, priority: entry.priority, indices: indices}
    if entry.priority then m.queue.Unshift(request) else m.queue.Push(request)
end sub

' Finds which archive.org server holds the files about to air, so the player can
' go to it directly instead of through a redirect on every request. Two small
' lookups per item: its server, then its folder on that server.
sub workerQueueResolves(entry as Object, events as Object)
    if m.resolved = invalid
        m.resolved = {}
        m.resolved.SetModeCaseSensitive()
    end if
    now = CreateObject("roDateTime").AsSeconds()
    queued = 0
    for each event in events
        if queued >= 3 then exit for
        if event.startSec + event.duration > now and event.url <> ""
            identifier = spelunkrArchiveIdentifier(event.url)
            if identifier <> "" and not m.resolved.DoesExist(identifier)
                ' Server and folder are independent lookups, so both go out together.
                m.resolved[identifier] = {server: "", dir: ""}
                base = "https://archive.org/metadata/" + identifier.EncodeUriComponent()
                serverRequest = {kind: "resolve", id: identifier, step: "server", priority: entry.priority, manifest: base + "/server"}
                dirRequest = {kind: "resolve", id: identifier, step: "dir", priority: entry.priority, manifest: base + "/dir"}
                if entry.priority
                    m.queue.Unshift(dirRequest)
                    m.queue.Unshift(serverRequest)
                else
                    m.queue.Push(serverRequest)
                    m.queue.Push(dirRequest)
                end if
                queued = queued + 1
            end if
        end if
    end for
end sub

sub workerResolveStep(entry as Object, answer as Dynamic)
    if type(answer) <> "roAssociativeArray" then return
    value = spelunkrText(answer.result)
    if value = "" then return
    parts = m.resolved[entry.id]
    if type(parts) <> "roAssociativeArray" then return
    if entry.step = "server"
        parts.server = value
    else if Left(value, 1) = "/"
        parts.dir = value
    end if
    if parts.server <> "" and parts.dir <> ""
        workerEmit({id: "", resolved: [{identifier: entry.id, base: "https://" + parts.server + parts.dir}]})
    end if
end sub

function spelunkrArchiveIdentifier(url as String) as String
    prefix = "https://archive.org/download/"
    if Left(url, Len(prefix)) <> prefix then return ""
    rest = Mid(url, Len(prefix) + 1)
    slash = Instr(1, rest, "/")
    if slash < 2 then return ""
    return Left(rest, slash - 1)
end function

sub workerPublishDescriptions(entry as Object, details as Dynamic)
    if type(details) <> "roAssociativeArray" then return
    if type(details.items) <> "roArray" then return
    descriptions = {}
    for each index in entry.indices
        if index < details.items.Count()
            detail = details.items[index]
            if type(detail) = "roAssociativeArray"
                text = spelunkrText(detail.description)
                if text <> "" then descriptions[index.ToStr()] = Left(text, 240)
            end if
        end if
    end for
    if descriptions.Count() > 0 then workerEmit({id: entry.id, ok: true, descriptions: descriptions})
end sub

sub workerExpireRequests()
    nowMs = m.elapsedTimer.TotalMilliseconds()
    for each key in m.inFlight.Keys()
        request = m.inFlight[key]
        if nowMs - request.startedMs > 10000
            request.transfer.AsyncCancel()
            m.inFlight.Delete(key)
            if request.entry.kind = "manifest" then workerEmit({id: request.entry.id, ok: false})
        end if
    end for
end sub

function spelunkrTransfer(url as String) as Object
    transfer = CreateObject("roUrlTransfer")
    ' Public HTTPS only needs the CA bundle. InitClientCertificates() is
    ' deprecated and was never needed here (no client-certificate servers).
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.EnableEncodings(true)
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("User-Agent", "SpelunkrRoku/1.0")
    transfer.SetUrl(url)
    return transfer
end function

function spelunkrJson(url as String) as Dynamic
    for attempt = 1 to 2
        if attempt > 1 then m.top.status = "Retrying live lineup..."
        transfer = spelunkrTransfer(url)
        port = CreateObject("roMessagePort")
        transfer.SetMessagePort(port)
        if transfer.AsyncGetToString()
            event = Wait(6000, port)
            if type(event) = "roUrlEvent"
                if event.GetInt() = 1 and event.GetResponseCode() >= 200 and event.GetResponseCode() < 300
                    response = event.GetString()
                    transfer = invalid
                    if response <> invalid
                        if response <> "" then return ParseJson(response)
                    end if
                end if
            else
                transfer.AsyncCancel()
            end if
        end if
        transfer = invalid
    end for
    return invalid
end function

function spelunkrCurrentVersion(versions as Dynamic, nowSec as Integer) as Dynamic
    if type(versions) <> "roArray" then return invalid
    if versions.Count() = 0 then return invalid
    selected = invalid
    earliest = invalid
    selectedTime = 0
    earliestTime = 0
    for each candidate in versions
        effective = candidate.effectiveAtMs
        if effective = invalid then effective = candidate.epochMs
        if effective = invalid then continue for
        effectiveSec = spelunkrMsToSeconds(effective)
        if earliest = invalid or effectiveSec < earliestTime
            earliest = candidate
            earliestTime = effectiveSec
        end if
        if effectiveSec <= nowSec and (selected = invalid or effectiveSec >= selectedTime)
            selected = candidate
            selectedTime = effectiveSec
        end if
    end for
    if selected = invalid then selected = earliest
    if selected = invalid then return invalid
    ' epochMs is the start of this version's broadcast clock. It can be earlier
    ' than effectiveAtMs, which only says when the version takes over.
    epoch = selected.epochMs
    if epoch = invalid then epoch = selected.effectiveAtMs
    startIndex = 0
    if selected.startIndex <> invalid then startIndex = Int(Val(spelunkrText(selected.startIndex)))
    epochSec = spelunkrMsToSeconds(epoch)
    remainder = bcToInteger(epoch * 1# - epochSec * 1000#)
    return {manifest: selected.manifest, details: spelunkrText(selected.details), version: selected.v, epochSec: epochSec, epochMsRem: remainder, startIndex: startIndex}
end function

' Upstream times are 13-digit milliseconds, too large for a 32-bit Integer. All
' app time is whole epoch seconds, so nothing can overflow in `seconds * 1000`.
function spelunkrMsToSeconds(value as Dynamic) as Integer
    return bcSeconds(value * 1#)
end function

' Lays the broadcast out on the wall clock: the first cycle runs from startIndex
' to the end of the list, later cycles from the top. Every event carries its
' absolute start, so "what is on now" never depends on when the app loaded it.
function spelunkrBuildSchedule(items as Object, entry as Object, nowSec as Integer, windowStartSec as Integer, windowEndSec as Integer) as Dynamic
    count = items.Count()
    if count = 0 then return invalid
    startIndex = entry.startIndex
    if startIndex < 0 or startIndex >= count then startIndex = 0
    durations = []
    totalSeconds = 0
    firstCycleSeconds = 0
    for index = 0 to count - 1
        itemDuration = Int(Val(spelunkrText(items[index].duration)))
        if itemDuration < 0 then itemDuration = 0
        durations.Push(itemDuration)
        totalSeconds = totalSeconds + itemDuration
        if index >= startIndex then firstCycleSeconds = firstCycleSeconds + itemDuration
    end for
    if totalSeconds <= 0 then return invalid

    epochSec = entry.epochSec
    ' A version not on air yet (or a wrong device clock) still has to show something.
    if epochSec > nowSec then epochSec = windowStartSec
    cursor = startIndex
    eventStartSec = epochSec
    if windowStartSec > epochSec
        elapsed = windowStartSec - epochSec
        if elapsed >= firstCycleSeconds
            elapsed = (elapsed - firstCycleSeconds) mod totalSeconds
            cursor = 0
        end if
        eventStartSec = windowStartSec - elapsed
        guard = 0
        while guard <= count and elapsed >= durations[cursor]
            elapsed = elapsed - durations[cursor]
            eventStartSec = eventStartSec + durations[cursor]
            cursor = (cursor + 1) mod count
            guard = guard + 1
        end while
    end if

    events = []
    guard = 0
    while eventStartSec < windowEndSec and guard < 400
        itemDuration = durations[cursor]
        if itemDuration > 0
            event = spelunkrItem(items[cursor], cursor)
            event.duration = itemDuration
            event.startSec = eventStartSec
            events.Push(event)
            eventStartSec = eventStartSec + itemDuration
        end if
        cursor = (cursor + 1) mod count
        guard = guard + 1
    end while
    return {id: entry.id, ok: true, events: events, endSec: eventStartSec}
end function

function spelunkrItem(item as Object, index as Integer) as Object
    ' Manifests mostly use `id` + `mp4`, but some archive records use `file`
    ' and a few publish a ready-to-play URL. Resolve all of those here so the
    ' guide and player cannot disagree about whether a program is playable.
    identifier = spelunkrFirstText(item, ["id", "identifier", "archiveId", "archive"])
    fileName = spelunkrFirstText(item, ["mp4", "file", "filename", "videoFile", "sourceFile"])
    url = spelunkrFirstText(item, ["url", "videoUrl", "streamUrl", "src", "playlist"])
    streamFormat = spelunkrFirstText(item, ["streamFormat", "mimeType"])
    if url = "" and fileName <> "" and (Instr(1, LCase(fileName), "https://") = 1 or Instr(1, LCase(fileName), "http://") = 1)
        url = fileName
    end if
    if url = "" and identifier <> "" and fileName <> ""
        url = "https://archive.org/download/" + identifier + "/" + spelunkrPathEscape(fileName)
    end if
    if streamFormat = ""
        if LCase(Right(url, 5)) = ".m3u8" or Instr(1, LCase(url), ".m3u8?") > 0
            streamFormat = "hls"
        else
            streamFormat = "mp4"
        end if
    end if
    title = spelunkrText(item.title)
    if title = "" then title = identifier
    ' `inS` is where the broadcast starts inside the file, for recordings with a
    ' trimmed head. `duration` already excludes the trim.
    fileStart = 0
    if item.inS <> invalid then fileStart = Int(Val(spelunkrText(item.inS)))
    if fileStart < 0 then fileStart = 0
    return {kind: "video", index: index, title: title, description: Left(spelunkrText(item.description), 240), year: spelunkrText(item.year), url: url, streamFormat: streamFormat, inS: fileStart, moov: spelunkrWhole(item.moov)}
end function

function spelunkrWhole(value as Dynamic) as Integer
    if value = invalid then return 0
    number = Int(Val(spelunkrText(value)))
    if number < 0 then return 0
    return number
end function

function spelunkrFirstText(item as Object, fields as Object) as String
    if type(item) <> "roAssociativeArray" then return ""
    for each fieldName in fields
        if item.DoesExist(fieldName)
            value = spelunkrText(item[fieldName])
            if value <> "" then return value
        end if
    end for
    return ""
end function

function spelunkrText(value as Dynamic) as String
    if value = invalid then return ""
    if type(value) = "String" then return value
    return value.ToStr()
end function

function spelunkrPathEscape(value as String) as String
    ' Archive filenames include unicode punctuation, ampersands, slashes and
    ' other reserved characters. Encode the complete filename as one URL path
    ' component (UTF-8), rather than leaving Roku with a malformed URL.
    return value.EncodeUriComponent()
end function
