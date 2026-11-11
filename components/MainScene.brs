sub init()
    ' FindNode walks the tree, so every node the guide updates is looked up once here.
    m.status = m.top.FindNode("status")
    m.previewVideo = m.top.FindNode("previewVideo")
    m.previewStatic = m.top.FindNode("previewStatic")
    m.staticAnimation = m.top.FindNode("staticAnimation")
    m.staticAnimating = false
    m.previewStatic.ObserveField("visible", "onStaticVisible")
    m.staticFade = m.top.FindNode("staticFade")
    m.staticFading = false
    m.staticFade.ObserveField("state", "onStaticFadeState")
    m.previewBadge = m.top.FindNode("previewBadge")
    m.previewBadgeText = m.top.FindNode("previewBadgeText")
    m.breakCard = m.top.FindNode("breakCard")
    m.breakText = m.top.FindNode("breakText")
    m.guideBack = m.top.FindNode("guideBack")
    m.guideFront = m.top.FindNode("guideFront")
    m.headerRule = m.top.FindNode("headerRule")
    m.previewEdge = m.top.FindNode("previewEdge")
    m.previewInfoEdge = m.top.FindNode("previewInfoEdge")
    ' Every panel border takes the selected channel's color, so the frame reads as one piece.
    m.accentEdges = [m.headerRule, m.previewEdge, m.previewInfoEdge, m.top.FindNode("infoRightEdge"), m.top.FindNode("listEdge"), m.top.FindNode("listRightEdge")]
    
    m.clockLabel = m.top.FindNode("clock")
    m.channelLogo = m.top.FindNode("channelPixelLogo")
    m.channelName = m.top.FindNode("channelName")
    m.directory = m.top.FindNode("directory")
    m.directoryCards = m.top.FindNode("directoryCards")
    m.directoryPage = m.top.FindNode("directoryPage")
    m.directoryOpen = false
    m.dirIndex = 0
    m.dirButton = 0
    m.dirRenderedPage = -1
    m.dirViews = []
    m.pendingTuneId = ""
    m.pendingDeepLink = invalid
    m.launchSignaled = false
    ' Screensaver policy: after this long with no remote input on the guide, the
    ' preview stops so the Roku screensaver can start. Full screen is unaffected.
    m.idleSeconds = 300
    m.lastInputSec = 0
    m.idlePaused = false
    ' Play/Pause in full screen. A paused video lets the Roku screensaver start.
    m.userPaused = false
    m.nowTitle = m.top.FindNode("nowTitle")
    m.nowDescription = m.top.FindNode("nowDescription")
    m.nowMeta = m.top.FindNode("nowMeta")
    m.nextTitle = m.top.FindNode("nextTitle")
    m.progressFill = m.top.FindNode("progressFill")
    m.guideTimes = m.top.FindNode("guideTimes")
    m.guideNextHeading = m.top.FindNode("guideNextHeading")
    m.guideThirdHeading = m.top.FindNode("guideThirdHeading")
    m.selectionBar = m.top.FindNode("selectionBar")
    m.selectionEdge = m.top.FindNode("selectionEdge")
    m.rowContent = m.top.FindNode("rowContent")
    m.playerBanner = m.top.FindNode("playerBanner")
    m.playerChannel = m.top.FindNode("playerChannel")
    m.playerTitle = m.top.FindNode("playerTitle")
    m.playerTime = m.top.FindNode("playerTime")
    m.playerProgressFill = m.top.FindNode("playerProgressFill")

    m.previewVideo.ObserveField("state", "onPreviewState")
    m.previewVideo.notificationInterval = 1
    m.active = false
    m.channels = []
    m.channelIndexById = {}
    m.rowViews = []
    m.currentIndex = 0
    m.renderedPage = -1
    m.requestedPage = -1
    m.lastRequestSec = 0
    m.fullscreen = false
    m.clock = CreateObject("roDateTime")
    m.lastMinute = -1
    m.hourStartSec = -1
    m.infoAiringKey = ""
    m.previewPending = false
    m.previewKey = ""
    m.previewHasStream = false
    m.previewNotice = ""
    m.previewAttemptKey = ""
    m.previewRetries = 0
    m.previewRetryAt = 0
    m.previewStartedAt = 0
    ' How long a stream takes to show a picture: a fixed part plus its index
    ' (moov) download and parse, learned from real opens on this TV.
    m.openTimer = CreateObject("roTimespan")
    m.openBaseSec = 2.0
    m.openBytesPerSec = 1500000.0
    m.openMoov = 0
    m.lastVideoPosition = -1.0
    m.previewDirectId = ""
    m.directBases = {}
    m.directBases.SetModeCaseSensitive()
    m.directFailed = {}
    m.directFailed.SetModeCaseSensitive()
    m.previewSeekFixes = 0
    m.driftCheckAt = 0
    m.userSeeked = false
    m.top.SetFocus(true)

    buildGuideRows()
    buildDirectoryCards()
    startLineupTask()

    m.tickTimer = CreateObject("roSGNode", "Timer")
    m.tickTimer.Duration = 1
    m.tickTimer.Repeat = true
    m.tickTimer.ObserveField("fire", "onTick")
    m.top.AppendChild(m.tickTimer)
    m.tickTimer.Control = "start"
    m.previewTimer = CreateObject("roSGNode", "Timer")
    ' Opening a stream means fetching a 2-12 MB index first, so opening one for
    ' every channel passed on the way only delays the one the viewer lands on.
    m.previewTimer.Duration = 0.6
    m.previewTimer.Repeat = false
    m.previewTimer.ObserveField("fire", "finishStaticTransition")
    m.top.AppendChild(m.previewTimer)
    m.scheduleLoadTimer = CreateObject("roSGNode", "Timer")
    m.scheduleLoadTimer.Duration = 0.25
    m.scheduleLoadTimer.Repeat = false
    m.scheduleLoadTimer.ObserveField("fire", "requestSchedules")
    m.top.AppendChild(m.scheduleLoadTimer)
    m.playbackBannerTimer = CreateObject("roSGNode", "Timer")
    m.playbackBannerTimer.Duration = 5
    m.playbackBannerTimer.Repeat = false
    m.playbackBannerTimer.ObserveField("fire", "hidePlaybackBanner")
    m.top.AppendChild(m.playbackBannerTimer)
    onTick()
end sub

sub startLineupTask()
    if m.task <> invalid
        m.task.UnobserveField("status")
        m.task.UnobserveField("complete")
        m.task.Control = "STOP"
    end if
    m.task = CreateObject("roSGNode", "GuideTask")
    m.task.ObserveField("status", "onGuideStatus")
    m.task.ObserveField("complete", "onGuideReady")
    m.task.Control = "RUN"
end sub

sub onGuideStatus()
    if m.task = invalid then return
    m.status.Text = m.task.status
end sub

sub onGuideReady()
    if m.task = invalid then return
    if not m.task.complete then return
    channels = m.task.channels
    if type(channels) <> "roArray" or channels.Count() = 0
        m.status.Text = m.task.status
        signalLaunchComplete()
        return
    end if
    m.channels = channels
    for index = 0 to m.channels.Count() - 1
        m.channelIndexById[m.channels[index].id] = index
    end for
    ' The finished task would otherwise keep a second copy of the whole lineup.
    m.task.UnobserveField("status")
    m.task.UnobserveField("complete")
    m.task = invalid
    m.scheduleTask = CreateObject("roSGNode", "GuideTask")
    m.scheduleTask.functionName = "runScheduleWorker"
    m.scheduleTask.ObserveField("scheduleResult", "onScheduleResult")
    m.scheduleTask.Control = "RUN"
    m.status.Text = ""
    m.top.SetFocus(true)
    m.active = true
    showChannel(0, true)
    requestSchedules()
    m.lastInputSec = currentEpochSeconds()
    signalLaunchComplete()
    if m.pendingDeepLink <> invalid then applyDeepLink()
end sub

' Certification 3.2: fired once, when the guide is usable (or shows its load error).
sub signalLaunchComplete()
    if m.launchSignaled = true then return
    m.launchSignaled = true
    m.top.signalBeacon("AppLaunchComplete")
end sub

' Deep links (certification 5.2): contentId is a channel id ("primetime") or a
' dial number ("8", "08", "300"). The channel plays full screen. A link that
' arrives before the lineup has loaded waits for it.
sub onDeepLink()
    link = m.top.deepLink
    if type(link) <> "roAssociativeArray" then return
    m.pendingDeepLink = link
    if m.active then applyDeepLink()
end sub

sub applyDeepLink()
    link = m.pendingDeepLink
    m.pendingDeepLink = invalid
    if link = invalid then return
    index = deepLinkIndex(LCase(link.contentId))
    if index < 0
        print "Deep link: no channel for contentId "; link.contentId
        return
    end if
    m.lastInputSec = currentEpochSeconds()
    if m.idlePaused then resumeIdlePreview(false)
    if m.directoryOpen then closeDirectory()
    if m.fullscreen then exitFullscreen()
    m.pendingTuneId = ""
    showChannel(index, true)
    requestSchedules()
    tuneInFullscreen(index)
end sub

function deepLinkIndex(contentId as String) as Integer
    if m.channelIndexById.DoesExist(contentId) then return m.channelIndexById[contentId]
    dial = Val(contentId)
    if dial <= 0 then return -1
    for index = 0 to m.channels.Count() - 1
        if Val(m.channels[index].dial) = dial then return index
    end for
    return -1
end function

' A low-memory warning from Main: drop the preview stream while it is not what
' the viewer is watching. The guide restarts it on the next channel change.
' Screensaver policy (idle guide): stop the preview and its static so no video or
' animation keeps the Roku screensaver away. Guide listings keep updating.
sub pauseIdlePreview()
    m.idlePaused = true
    m.previewTimer.Control = "stop"
    m.previewPending = false
    stopPreview()
    hideStatic()
    m.previewVideo.Visible = false
    m.previewBadgeText.Text = "PREVIEW PAUSED  ·  PRESS ANY BUTTON"
    m.previewBadge.Visible = true
end sub

sub resumeIdlePreview(restart as Boolean)
    m.idlePaused = false
    m.previewBadge.Visible = false
    m.previewVideo.Visible = true
    if restart and not m.fullscreen and not m.directoryOpen then showChannel(m.currentIndex, true)
end sub

sub onLowMemory()
    if m.fullscreen then return
    m.previewTimer.Control = "stop"
    m.previewPending = false
    stopPreview()
    showStatic()
end sub

sub showChannel(index as Integer, preview as Boolean)
    if index < 0 or index >= m.channels.Count() then return
    m.currentIndex = index
    channel = m.channels[index]
    refreshChannelSchedule(channel)
    accent = spelunkrColor(channel.color)
    for each edge in m.accentEdges
        edge.Color = accent
    end for
    m.channelLogo.Uri = channel.logoUri
    m.channelName.Text = channel.name
    updateProgramInfo(channel)
    page = Int(index / 8)
    if page <> m.renderedPage
        renderGuideRows()
        if page <> m.requestedPage
            m.scheduleLoadTimer.Control = "stop"
            m.scheduleLoadTimer.Control = "start"
        end if
    else
        updateSelection()
    end if
    if channel.timelineLoaded then m.status.Text = "" else m.status.Text = "Loading listings..."
    if preview and not m.fullscreen
        ' Release the old stream on the first press so scrolling is not fighting
        ' the decoder and its audio does not play over the static. The new one
        ' only starts once navigation settles.
        stopPreview()
        showStatic()
        m.previewPending = true
        updateTuningBadge(currentEpochSeconds())
        m.previewTimer.Control = "stop"
        m.previewTimer.Control = "start"
    end if
end sub

sub updateProgramInfo(channel as Object)
    m.infoAiringKey = airingKey(channel)
    program = channel.now
    if program <> invalid
        m.nowTitle.Text = program.title
        m.nowDescription.Text = programDescription(channel, program)
        nextTitle = "UP NEXT"
        if channel.next <> invalid then nextTitle = nextTitle + "  " + channel.next.title
        m.nextTitle.Text = nextTitle
        updateProgress(channel)
    else
        m.nowTitle.Text = "Guide details loading"
        m.nowDescription.Text = ""
        m.nowMeta.Text = ""
        m.nextTitle.Text = "UP NEXT"
        m.progressFill.Width = 1
    end if
end sub

function programDescription(channel as Object, program as Object) as String
    if program.kind <> "video" then return ""
    key = program.index.ToStr()
    if channel.descriptions.DoesExist(key) then return channel.descriptions[key]
    return program.description
end function

sub updateProgress(channel as Object)
    program = channel.now
    if program = invalid then return
    meta = spelunkrDuration(channel.elapsed) + " / " + spelunkrDuration(program.duration)
    if program.year <> "" then meta = meta + "  ·  " + program.year
    m.nowMeta.Text = meta
    progress = Int(650 * channel.elapsed / program.duration)
    if progress < 1 then progress = 1
    if progress > 650 then progress = 650
    m.progressFill.Width = progress
end sub

' The guide keeps one fixed set of row nodes for its whole lifetime and rewrites
' their values on a page change, so the node count cannot grow as you browse.
sub buildGuideRows()
    dialFont = CreateObject("roSGNode", "Font")
    dialFont.Uri = "font:MediumBoldSystemFont"
    dialFont.Size = 23
    nameFont = CreateObject("roSGNode", "Font")
    nameFont.Uri = "font:SmallestSystemFont"
    nameFont.Size = 14
    for slot = 0 to 7
        row = m.rowContent.CreateChild("Group")
        row.Translation = [0, slot * 35]
        ' Wide enough for three-digit dials (100s-600s) and the longest channel
        ' name, COMPUTER CHRONICLES, without ellipsis.
        dialShadow = addRowLabel(row, 2, 1, 54, dialFont, "0x000000FF")
        dial = addRowLabel(row, 0, 0, 54, dialFont, "0xFFE22EFF")
        logo = row.CreateChild("Poster")
        logo.Translation = [57, 3]
        logo.Width = 28
        logo.Height = 28
        logo.LoadDisplayMode = "scaleToFit"
        name = addRowLabel(row, 89, 0, 214, nameFont, "0xFFE22EFF")
        name.HorizAlign = "left"
        m.rowViews.Push({group: row, logo: logo, dial: dial, dialShadow: dialShadow, name: name, cellLayer: row.CreateChild("Group"), cells: [], highlightStart: -1})
    end for
end sub

function addRowLabel(parent as Object, x as Integer, y as Integer, w as Integer, font as Object, color as String) as Object
    label = parent.CreateChild("Label")
    label.Translation = [x, y]
    label.Width = w
    label.Height = 35
    label.HorizAlign = "center"
    label.VertAlign = "center"
    label.Font = font
    label.Color = color
    return label
end function

sub renderGuideRows()
    page = Int(m.currentIndex / 8)
    m.renderedPage = page
    first = page * 8
    for slot = 0 to 7
        view = m.rowViews[slot]
        channelIndex = first + slot
        if channelIndex < m.channels.Count()
            channel = m.channels[channelIndex]
            view.logo.Uri = channel.logoUri
            view.dial.Text = channel.dial
            view.dialShadow.Text = channel.dial
            view.name.Text = channel.name
            renderRowCells(slot, channel)
            view.group.Visible = true
        else
            view.group.Visible = false
        end if
    end for
    updateSelection()
end sub

sub updateSelection()
    y = (m.currentIndex - m.renderedPage * 8) * 35
    m.selectionBar.Translation = [0, y]
    m.selectionEdge.Translation = [0, y]
end sub

sub renderRowCells(slot as Integer, channel as Object)
    view = m.rowViews[slot]
    refreshChannelSchedule(channel)
    nowStart = -1
    if channel.now <> invalid then nowStart = channel.now.startSec
    view.highlightStart = nowStart
    used = 0
    ' Keep in step with the hour headings and dividers in MainScene.xml. The axis
    ' ends flush with the selection bar's right edge.
    axisX = 306
    axisWidth = 891
    windowSeconds = 10800
    for each item in channel.timeline
        clipStart = item.startSec - m.hourStartSec
        if clipStart >= windowSeconds then exit for
        clipEnd = clipStart + item.duration
        if clipStart < 0 then clipStart = 0
        if clipEnd > windowSeconds then clipEnd = windowSeconds
        x = axisX + Int(clipStart * axisWidth / windowSeconds)
        right = axisX + Int(clipEnd * axisWidth / windowSeconds)
        cellWidth = right - x
        ' Breaks stay as gaps between programs, as on a printed guide.
        if cellWidth >= 2 and item.kind = "video"
            if used >= 40 then exit for
            cell = rowCell(view, used)
            used = used + 1
            cell.rect.Translation = [x, 1]
            cell.rect.Width = cellWidth
            if item.startSec = nowStart then cell.rect.Color = "0x344A91FF" else cell.rect.Color = "0x23377AFF"
            if cellWidth >= 42
                if cell.title = invalid
                    cell.title = addGuideLabel(cell.rect, 5, 0, 0, 18, "font:SmallSystemFont", "0xE8EAF0FF")
                    cell.length = addGuideLabel(cell.rect, 5, 18, 0, 13, "font:SmallestSystemFont", "0xC7D2F2FF")
                end if
                cell.title.Width = cellWidth - 9
                cell.title.Text = item.title
                cell.length.Width = cellWidth - 9
                cell.length.Text = spelunkrDuration(item.duration)
                cell.title.Visible = true
                cell.length.Visible = true
            else if cell.title <> invalid
                cell.title.Visible = false
                cell.length.Visible = false
            end if
            cell.rect.Visible = true
        end if
    end for
    for index = used to view.cells.Count() - 1
        view.cells[index].rect.Visible = false
    end for
end sub

function rowCell(view as Object, index as Integer) as Object
    if index < view.cells.Count() then return view.cells[index]
    rect = view.cellLayer.CreateChild("Rectangle")
    rect.Height = 33
    cell = {rect: rect, title: invalid, length: invalid}
    view.cells.Push(cell)
    return cell
end function

function addGuideLabel(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, fontName as String, color as String) as Object
    label = parent.CreateChild("Label")
    label.Translation = [x, y]
    label.Width = w
    label.Height = h
    label.Font = fontName
    label.Color = color
    return label
end function

' Asks the worker for everything that is missing, nearest channels first: the
' selected channel, its page, then outward. Once a channel's listings are in,
' page jumps and previews on it need no network at all.
sub requestSchedules()
    if m.scheduleTask = invalid then return
    count = m.channels.Count()
    if count = 0 then return
    page = Int(m.currentIndex / 8)
    m.requestedPage = page
    m.lastRequestSec = currentEpochSeconds()
    pageCount = Int((count + 7) / 8)
    ' The worker returns six hours, so channels only refresh every couple of hours.
    horizon = m.hourStartSec + 14400
    queue = []
    addScheduleRequest(queue, m.currentIndex, true, horizon)
    addPageRequests(queue, page, true, horizon)
    for distance = 1 to pageCount - 1
        addPageRequests(queue, page + distance, false, horizon)
        addPageRequests(queue, page - distance, false, horizon)
    end for
    if queue.Count() > 0 then m.scheduleTask.scheduleQueue = queue
end sub

sub addPageRequests(queue as Object, page as Integer, priority as Boolean, horizon as Integer)
    if page < 0 then return
    for slot = 0 to 7
        channelIndex = page * 8 + slot
        if channelIndex >= m.channels.Count() then return
        if channelIndex <> m.currentIndex then addScheduleRequest(queue, channelIndex, priority, horizon)
    end for
end sub

sub addScheduleRequest(queue as Object, channelIndex as Integer, priority as Boolean, horizon as Integer)
    channel = m.channels[channelIndex]
    if channel.schedule = invalid then return
    if channel.timelineLoaded and channel.timelineEndSec >= horizon then return
    schedule = channel.schedule
    queue.Push({kind: "manifest", id: channel.id, manifest: schedule.manifest, details: schedule.details, version: schedule.version, epochSec: schedule.epochSec, epochMsRem: schedule.epochMsRem, startIndex: schedule.startIndex, priority: priority})
end sub

sub onScheduleResult(event as Object)
    result = event.GetData()
    if type(result) <> "roAssociativeArray" then return
    if result.DoesExist("resolved")
        for each pair in result.resolved
            m.directBases[pair.identifier] = pair.base
        end for
        return
    end if
    if not m.channelIndexById.DoesExist(result.id) then return
    channelIndex = m.channelIndexById[result.id]
    channel = m.channels[channelIndex]
    if result.DoesExist("descriptions")
        channel.descriptions.Append(result.descriptions)
        if channelIndex = m.currentIndex then updateProgramInfo(channel)
        return
    end if
    if result.ok = true
        channel.timeline = result.events
        channel.timelineEndSec = result.endSec
        channel.timelineLoaded = true
        channel.nowIndex = 0
    end if
    if Int(channelIndex / 8) = m.renderedPage then renderRowCells(channelIndex - m.renderedPage * 8, channel)
    if m.directoryOpen
        if Int(channelIndex / 4) = m.dirRenderedPage then updateDirectoryNow()
        return
    end if
    if channelIndex <> m.currentIndex then return
    ' Tune In from the directory waits here for the channel's listings.
    if m.pendingTuneId = channel.id and channel.timelineLoaded
        m.pendingTuneId = ""
        refreshChannelSchedule(channel)
        if channel.now <> invalid
            enterFullscreen()
            return
        end if
    end if
    if channel.timelineLoaded
        m.status.Text = ""
        updateProgramInfo(channel)
        if not m.previewPending then startPreview(channel)
    else
        m.status.Text = "Listings unavailable. Retrying..."
    end if
end sub

sub finishStaticTransition()
    ' Also used by channel up/down in full screen, so it runs in both views.
    if not m.previewPending then return
    m.previewPending = false
    startPreview(m.channels[m.currentIndex])
end sub

sub showStatic()
    cancelStaticFade()
    m.previewStatic.Visible = true
end sub

sub hideStatic()
    cancelStaticFade()
    m.previewStatic.Visible = false
end sub

' The picture appears by dissolving the static away from in front of it.
sub fadeOutStatic()
    if m.staticFading or not m.previewStatic.Visible then return
    m.staticFading = true
    m.previewBadge.Visible = false
    m.staticFade.Control = "start"
end sub

sub cancelStaticFade()
    if m.staticFading
        m.staticFading = false
        m.staticFade.Control = "stop"
    end if
    m.previewStatic.Opacity = 1
end sub

sub onStaticFadeState()
    if m.staticFading and m.staticFade.state = "stopped" then hideStatic()
end sub

' The static only animates while it shows, so it costs nothing behind a picture.
sub onStaticVisible()
    shouldAnimate = m.previewStatic.Visible
    if shouldAnimate = m.staticAnimating then return
    m.staticAnimating = shouldAnimate
    if shouldAnimate then m.staticAnimation.Control = "start" else m.staticAnimation.Control = "stop"
end sub

sub onPreviewState()
    state = m.previewVideo.state
    if m.previewKey = "" or not m.previewHasStream then return
    nowSec = currentEpochSeconds()
    if state = "playing"
        onStreamPlaying(nowSec)
    else if state = "error"
        print "Preview error for "; m.previewKey; ": "; m.previewVideo.errorCode; " "; m.previewVideo.errorMsg
        ' A direct server link that fails is not used again; retries go through archive.org.
        if m.previewDirectId <> "" then m.directFailed[m.previewDirectId] = true
        showStatic()
        m.previewStartedAt = 0
        if m.previewRetries < 2
            m.previewRetries = m.previewRetries + 1
            m.previewKey = ""
            m.previewRetryAt = nowSec + 4
        else
            m.previewNotice = "NO SIGNAL"
        end if
    else if state = "finished"
        ' The file ran out before its slot did. Hold on static, as a station
        ' would, until the next program; replaying it would restart the show.
        showStatic()
        m.previewNotice = "OFF AIR UNTIL NEXT PROGRAM"
    end if
    updateTuningBadge(nowSec)
end sub

' The picture is up: dissolve the static and learn how long this open took.
sub onStreamPlaying(nowSec as Integer)
    fadeOutStatic()
    m.previewNotice = ""
    if m.previewStartedAt > 0
        learnOpenTime(m.openTimer.TotalMilliseconds() / 1000.0, m.openMoov)
        m.previewStartedAt = 0
    end if
    if m.driftCheckAt = 0 or m.driftCheckAt > nowSec + 3 then m.driftCheckAt = nowSec + 3
end sub

function predictOpenSeconds(moovBytes as Integer) as Integer
    seconds = Int(m.openBaseSec + moovBytes / m.openBytesPerSec + 0.5)
    if seconds < 1 then seconds = 1
    if seconds > 40 then seconds = 40
    return seconds
end function

' Small indexes mostly measure the fixed part; big ones measure download and parse speed.
sub learnOpenTime(seconds as Float, moovBytes as Integer)
    if seconds <= 0 or seconds > 90 then return
    if moovBytes >= 1000000
        spent = seconds - m.openBaseSec
        if spent < 0.5 then spent = 0.5
        rate = moovBytes / spent
        if rate < 200000 then rate = 200000
        if rate > 20000000 then rate = 20000000
        m.openBytesPerSec = m.openBytesPerSec * 0.6 + rate * 0.4
    else
        base = seconds - moovBytes / m.openBytesPerSec
        if base < 0.5 then base = 0.5
        if base > 8 then base = 8
        m.openBaseSec = m.openBaseSec * 0.6 + base * 0.4
    end if
end sub

' Swaps an archive.org link for the server that holds the file, when the worker
' has looked it up, saving a redirect on every request the player makes.
function streamUrl(url as String) as String
    m.previewDirectId = ""
    identifier = archiveIdentifier(url)
    if identifier = "" then return url
    if not m.directBases.DoesExist(identifier) or m.directFailed.DoesExist(identifier) then return url
    m.previewDirectId = identifier
    return m.directBases[identifier] + "/" + Mid(url, 31 + Len(identifier))
end function

function archiveIdentifier(url as String) as String
    prefix = "https://archive.org/download/"
    if Left(url, Len(prefix)) <> prefix then return ""
    rest = Mid(url, Len(prefix) + 1)
    slash = Instr(1, rest, "/")
    if slash < 2 then return ""
    return Left(rest, slash - 1)
end function

sub layoutStatic()
    if m.fullscreen
        m.previewStatic.Translation = [0, 0]
        m.previewStatic.Scale = [1280 / 374, 720 / 210]
    else
        m.previewStatic.Translation = [95, 94]
        m.previewStatic.Scale = [1, 1]
    end if
end sub

' Says what the static means, so a slow stream is not mistaken for a broken one.
sub updateTuningBadge(nowSec as Integer)
    if m.idlePaused and not m.fullscreen then return
    if m.fullscreen or m.staticFading or not m.previewStatic.Visible
        m.previewBadge.Visible = false
        return
    end if
    text = "TUNING IN"
    if m.previewNotice <> ""
        text = m.previewNotice
    else if m.previewStartedAt > 0
        text = text + "  " + (nowSec - m.previewStartedAt).ToStr() + "s"
        status = m.previewVideo.bufferingStatus
        if type(status) = "roAssociativeArray"
            if status.percentage <> invalid then text = text + "  ·  " + status.percentage.ToStr() + "%"
        end if
    end if
    m.previewBadgeText.Text = text
    m.previewBadge.Visible = true
end sub

sub updateBreakCard(channel as Object)
    if m.idlePaused then return
    if channel.now = invalid then return
    if channel.now.kind <> "card" then return
    elapsedMs = channel.elapsed * 1000
    text = ""
    for each slide in channel.now.slides
        if slide.at <= elapsedMs then text = slide.text
    end for
    m.breakText.Text = text
end sub

sub layoutBreakCard()
    if m.fullscreen
        m.breakCard.Translation = [0, 0]
        m.breakCard.Width = 1280
        m.breakCard.Height = 720
        m.breakText.Translation = [120, 0]
        m.breakText.Width = 1040
        m.breakText.Height = 720
        m.breakText.Font = "font:LargeBoldSystemFont"
    else
        m.breakCard.Translation = [95, 94]
        m.breakCard.Width = 374
        m.breakCard.Height = 210
        m.breakText.Translation = [14, 0]
        m.breakText.Width = 346
        m.breakText.Height = 210
        m.breakText.Font = "font:SmallBoldSystemFont"
    end if
end sub

' Video position is checked a few seconds after playback settles, then every
' minute. If a slow open or a stall has moved the picture away from the
' broadcast, jump to it. The index is loaded by then, so a seek is quick.
sub checkPreviewDrift(nowSec as Integer, channel as Object)
    if m.driftCheckAt = 0 or nowSec < m.driftCheckAt then return
    m.driftCheckAt = 0
    if m.userSeeked or m.previewSeekFixes >= 3 then return
    if not m.previewHasStream or m.previewKey <> airingKey(channel) then return
    if m.previewVideo.state <> "playing" then return
    position = m.previewVideo.position
    if position < 1 then return
    expected = channel.elapsed + channel.now.inS
    if Abs(expected - position) > 10
        m.previewSeekFixes = m.previewSeekFixes + 1
        m.previewVideo.seek = expected + 2
    end if
    m.driftCheckAt = nowSec + 60
end sub

' Fills the fullscreen banner from the player's real position. Called once a
' second while it shows; it never changes whether the banner is visible.
sub renderPlaybackBanner()
    channel = m.channels[m.currentIndex]
    m.playerChannel.Text = "CH " + channel.dial + "  ·  " + channel.name
    program = channel.now
    position = 0
    duration = 0
    if program <> invalid
        m.playerTitle.Text = program.title
        duration = program.duration
        if program.kind = "card"
            position = channel.elapsed
        else
            position = Int(m.previewVideo.position) - program.inS
        end if
    else
        ' Flipped to a channel whose listings are still loading.
        m.playerTitle.Text = "Tuning in..."
    end if
    if position < 0 then position = 0
    if position > duration then position = duration
    m.playerTime.Text = spelunkrDuration(position) + "  /  " + spelunkrDuration(duration)
    if m.userPaused then m.playerTime.Text = "PAUSED"
    fill = 1
    if duration > 0 then fill = Int(1180 * position / duration)
    if fill < 1 then fill = 1
    if fill > 1180 then fill = 1180
    m.playerProgressFill.Width = fill
end sub

sub showPlaybackBanner()
    if not m.fullscreen then return
    renderPlaybackBanner()
    m.playerBanner.Visible = true
    m.playbackBannerTimer.Control = "stop"
    m.playbackBannerTimer.Control = "start"
end sub

sub hidePlaybackBanner()
    m.playerBanner.Visible = false
end sub

' Works out what is on air right now from the absolute times in the timeline, so
' a channel is correct however long ago it was loaded or last selected.
sub refreshChannelSchedule(channel as Object)
    if not channel.timelineLoaded then return
    events = channel.timeline
    count = events.Count()
    nowSec = currentEpochSeconds()
    index = channel.nowIndex
    if index >= count then index = 0
    if count > 0
        if nowSec < events[index].startSec then index = 0
    end if
    while index < count
        if nowSec < events[index].startSec + events[index].duration then exit while
        index = index + 1
    end while
    channel.now = invalid
    channel.next = invalid
    channel.elapsed = 0
    if index >= count
        ' Ran past the end of the listings: fetch more on the next request.
        channel.timelineEndSec = 0
        channel.nowIndex = 0
        return
    end if
    channel.nowIndex = index
    if nowSec < events[index].startSec then return
    channel.now = events[index]
    channel.elapsed = nowSec - events[index].startSec
    ' "Up next" names the next program, not the next bumper.
    for nextIndex = index + 1 to count - 1
        if events[nextIndex].kind = "video"
            channel.next = events[nextIndex]
            exit for
        end if
    end for
end sub

function airingKey(channel as Object) as String
    if channel.now = invalid then return ""
    return channel.id + "@" + channel.now.startSec.ToStr()
end function

function currentEpochSeconds() as Integer
    m.clock.Mark()
    return m.clock.AsSeconds()
end function

sub stopPreview()
    m.previewRetryAt = 0
    m.driftCheckAt = 0
    m.previewStartedAt = 0
    m.lastVideoPosition = -1.0
    m.previewNotice = ""
    m.previewKey = ""
    m.breakCard.Visible = false
    if not m.previewHasStream then return
    m.previewHasStream = false
    m.previewVideo.Control = "stop"
    m.previewVideo.Content = invalid
end sub

' Tunes the player to the channel's current broadcast. Calling it again for the
' same airing leaves the stream alone. A new stream is always opened at the live
' point worked out now, so a show never restarts from an old position.
sub startPreview(channel as Object)
    if m.idlePaused and not m.fullscreen then return
    ' Stay paused across a program change; resume picks up the new airing.
    if m.userPaused and m.fullscreen then return
    refreshChannelSchedule(channel)
    key = airingKey(channel)
    if key = ""
        stopPreview()
        showStatic()
        return
    end if
    if key = m.previewKey then return
    program = channel.now
    stopPreview()
    if program.kind = "card"
        m.previewKey = key
        hideStatic()
        updateBreakCard(channel)
        m.breakCard.Visible = true
        m.previewBadge.Visible = false
        return
    end if
    if program.url = ""
        showStatic()
        m.previewNotice = "NO SIGNAL"
        return
    end if
    if key <> m.previewAttemptKey then m.previewRetries = 0
    m.previewAttemptKey = key
    moov = 0
    if program.moov <> invalid then moov = program.moov
    content = CreateObject("roSGNode", "ContentNode")
    content.Url = streamUrl(program.url)
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    content.Title = program.title
    content.StreamFormat = LCase(program.streamFormat)
    content.ContentType = "movie"
    content.Length = program.inS + program.duration
    ' Ask for where the broadcast will be once this file's index has loaded.
    startAt = channel.elapsed + predictOpenSeconds(moov)
    if startAt >= program.duration - 2 then startAt = channel.elapsed
    startAt = startAt + program.inS
    if startAt > 1 then content.PlayStart = startAt
    showStatic()
    m.previewKey = key
    m.previewHasStream = true
    m.previewStartedAt = currentEpochSeconds()
    m.openTimer.Mark()
    m.openMoov = moov
    m.lastVideoPosition = -1.0
    m.previewSeekFixes = 0
    m.userSeeked = false
    m.previewVideo.Content = content
    m.previewVideo.Control = "play"
    m.previewVideo.Visible = true
end sub

sub enterFullscreen()
    channel = m.channels[m.currentIndex]
    refreshChannelSchedule(channel)
    playable = false
    if channel.now <> invalid
        if channel.now.url <> "" or channel.now.kind = "card" then playable = true
    end if
    if not playable
        m.status.Text = "This program has no playable MP4 link."
        return
    end if
    m.fullscreen = true
    m.previewTimer.Control = "stop"
    m.previewPending = false
    layoutBreakCard()
    layoutStatic()
    startPreview(channel)
    ' Make sure what fills the screen is the live point, not a stalled preview.
    if m.previewHasStream and not m.userSeeked then m.driftCheckAt = currentEpochSeconds() + 1
    m.previewVideo.Translation = [0, 0]
    m.previewVideo.Width = 1280
    m.previewVideo.Height = 720
    ' Keep remote input on the scene so left/right are handled by our seek logic.
    ' A focused Video node consumes those keys as transport controls on some Roku models.
    m.top.SetFocus(true)
    hideGuideChrome(true)
    showPlaybackBanner()
end sub

' Play/Pause while watching. Resume rejoins the live broadcast: the same file
' seeks to the live point; a program that changed while paused opens fresh.
sub togglePause()
    if m.userPaused
        resumePlayback()
    else if m.previewHasStream
        m.userPaused = true
        m.previewVideo.control = "pause"
        m.driftCheckAt = 0
    end if
    showPlaybackBanner()
end sub

sub resumePlayback()
    if not m.userPaused then return
    m.userPaused = false
    channel = m.channels[m.currentIndex]
    refreshChannelSchedule(channel)
    if not m.previewHasStream or airingKey(channel) <> m.previewKey
        m.previewKey = ""
        startPreview(channel)
        return
    end if
    m.previewVideo.control = "resume"
    m.userSeeked = false
    m.previewSeekFixes = 0
    m.driftCheckAt = currentEpochSeconds() + 2
end sub

sub exitFullscreen()
    resumePlayback()
    m.fullscreen = false
    m.playbackBannerTimer.Control = "stop"
    m.playerBanner.Visible = false
    m.previewVideo.Translation = [95, 94]
    m.previewVideo.Width = 374
    m.previewVideo.Height = 210
    hideGuideChrome(false)
    layoutBreakCard()
    layoutStatic()
    if m.previewVideo.state = "playing" or m.breakCard.Visible then hideStatic() else showStatic()
    updateTuningBadge(currentEpochSeconds())
    updateProgramInfo(m.channels[m.currentIndex])
    m.top.SetFocus(true)
end sub

sub hideGuideChrome(hide as Boolean)
    m.guideBack.Visible = not hide
    m.guideFront.Visible = not hide
    ' The static stays: in full screen it covers the screen until the picture is up.
    if hide then m.previewBadge.Visible = false
end sub

sub moveSelection(delta as Integer)
    targetIndex = m.currentIndex + delta
    if targetIndex < 0 then targetIndex = 0
    if targetIndex >= m.channels.Count() then targetIndex = m.channels.Count() - 1
    if targetIndex = m.currentIndex then return
    m.pendingTuneId = ""
    showChannel(targetIndex, true)
end sub

' Channel up/down while watching full screen, like a TV: Up goes to the next
' higher dial, wrapping at either end. The new stream opens only once flipping
' settles (previewTimer), with static and the banner showing meanwhile.
sub fullscreenChannelStep(delta as Integer)
    count = m.channels.Count()
    if count < 2 then return
    target = (m.currentIndex + delta + count) mod count
    m.pendingTuneId = ""
    m.userPaused = false
    stopPreview()
    showStatic()
    showChannel(target, false)
    m.previewPending = true
    m.previewTimer.Control = "stop"
    m.previewTimer.Control = "start"
    requestSchedules()
    showPlaybackBanner()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    m.lastInputSec = currentEpochSeconds()
    if m.idlePaused
        ' Like a screensaver, the first press only wakes the preview.
        resumeIdlePreview(true)
        return true
    end if
    if m.directoryOpen then return onDirectoryKey(key)
    if m.fullscreen
        if key = "back" or key = "OK"
            exitFullscreen()
        else if key = "left" or key = "right"
            program = m.channels[m.currentIndex].now
            canSeek = false
            if program <> invalid then canSeek = program.kind <> "card"
            if canSeek
                target = m.previewVideo.position
                if key = "left" then target = target - 10 else target = target + 10
                if target < program.inS then target = program.inS
                if target > program.inS + program.duration then target = program.inS + program.duration
                m.userSeeked = true
                m.previewVideo.seek = target
            end if
            showPlaybackBanner()
        else if key = "play"
            togglePause()
        else if key = "up"
            fullscreenChannelStep(1)
        else if key = "down"
            fullscreenChannelStep(-1)
        else
            showPlaybackBanner()
        end if
        return true
    end if
    if key = "OK" and m.active
        enterFullscreen()
        return true
    else if key = "up" and m.active
        moveSelection(-1)
        return true
    else if key = "down" and m.active
        moveSelection(1)
        return true
    else if key = "left" and m.active
        moveSelection(-8)
        return true
    else if key = "right" and m.active
        moveSelection(8)
        return true
    else if key = "options" and m.active
        openDirectory()
        return true
    else if key = "options" or key = "replay"
        if not m.active
            startLineupTask()
            m.status.Text = "Refreshing Spelunkr guide..."
        end if
        return true
    end if
    return false
end function

' ---- Channel directory (mirrors spelunkr.tv/directory) ----------------------
' Four fixed cards, rewritten per page. Each card has the site's two buttons:
' TUNE IN plays the channel full screen, VIEW CHANNEL selects it in the guide.

sub buildDirectoryCards()
    dialFont = CreateObject("roSGNode", "Font")
    dialFont.Uri = "font:LargeBoldSystemFont"
    dialFont.Size = 40
    for slot = 0 to 3
        x = 32 + (slot mod 2) * 616
        y = 120 + Int(slot / 2) * 282
        card = m.directoryCards.CreateChild("Group")
        card.Translation = [x, y]
        border = dirBox(card, 0, 0, 600, 276, "0x3157A5FF")
        dirBox(card, 4, 4, 592, 268, "0x1F2A6BFF")
        dialShadow = dirLabel(card, 14, 10, 84, 54, "", "0x14153AFF")
        dialShadow.Font = dialFont
        dialShadow.HorizAlign = "center"
        dial = dirLabel(card, 12, 8, 84, 54, "", "0xFFE22EFF")
        dial.Font = dialFont
        dial.HorizAlign = "center"
        logo = card.CreateChild("Poster")
        logo.Translation = [102, 8]
        logo.Width = 54
        logo.Height = 54
        logo.LoadDisplayMode = "scaleToFit"
        name = dirLabel(card, 168, 12, 416, 30, "font:MediumBoldSystemFont", "0xFFE22EFF")
        family = dirLabel(card, 169, 42, 200, 18, "font:SmallestSystemFont", "0x99A3CCFF")
        description = dirLabel(card, 16, 68, 568, 110, "font:SmallSystemFont", "0xE8EAF0FF")
        description.Wrap = true
        description.MaxLines = 5
        stats = dirLabel(card, 16, 178, 568, 18, "font:SmallestSystemFont", "0x99A3CCFF")
        nowLabel = dirLabel(card, 16, 197, 200, 18, "font:SmallestBoldSystemFont", "0xFFD740FF")
        nowLabel.Text = "NOW PLAYING"
        nowTitle = dirLabel(card, 16, 214, 568, 22, "font:SmallSystemFont", "0xE8EAF0FF")
        tune = dirButton(card, 16, 240, 236, "TUNE IN", "0xB8500EFF", "0xFFE22EFF")
        view = dirButton(card, 262, 240, 322, "VIEW CHANNEL", "0x2B2FC4FF", "0xFFFFFFFF")
        m.dirViews.Push({group: card, border: border, dial: dial, dialShadow: dialShadow, logo: logo, name: name, family: family, description: description, stats: stats, nowLabel: nowLabel, nowTitle: nowTitle, buttons: [tune, view]})
    end for
end sub

function dirBox(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String) as Object
    rect = parent.CreateChild("Rectangle")
    rect.Translation = [x, y]
    rect.Width = w
    rect.Height = h
    rect.Color = color
    return rect
end function

function dirLabel(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, fontName as String, color as String) as Object
    label = parent.CreateChild("Label")
    label.Translation = [x, y]
    label.Width = w
    label.Height = h
    if fontName <> "" then label.Font = fontName
    label.Color = color
    return label
end function

function dirButton(parent as Object, x as Integer, y as Integer, w as Integer, text as String, fill as String, textColor as String) as Object
    outline = dirBox(parent, x, y, w, 32, "0x14153AFF")
    face = dirBox(parent, x + 2, y + 2, w - 4, 28, fill)
    shadow = dirLabel(parent, x + 1, y + 1, w, 32, "font:SmallBoldSystemFont", "0x14153AFF")
    shadow.Text = text
    shadow.HorizAlign = "center"
    shadow.VertAlign = "center"
    label = dirLabel(parent, x, y, w, 32, "font:SmallBoldSystemFont", textColor)
    label.Text = text
    label.HorizAlign = "center"
    label.VertAlign = "center"
    return {outline: outline, face: face, fill: fill}
end function

sub openDirectory()
    if m.channels.Count() = 0 then return
    m.directoryOpen = true
    m.pendingTuneId = ""
    ' Nothing plays behind the directory: no audio, no decoder load while browsing.
    m.previewTimer.Control = "stop"
    m.previewPending = false
    stopPreview()
    hideStatic()
    m.previewVideo.Visible = false
    m.previewBadge.Visible = false
    m.dirIndex = m.currentIndex
    m.dirButton = 0
    m.dirRenderedPage = -1
    m.guideFront.Visible = false
    m.directory.Visible = true
    renderDirectory()
end sub

sub closeDirectory()
    m.directoryOpen = false
    m.directory.Visible = false
    m.guideFront.Visible = true
    m.previewVideo.Visible = true
end sub

sub renderDirectory()
    page = Int(m.dirIndex / 4)
    if page <> m.dirRenderedPage
        m.dirRenderedPage = page
        for slot = 0 to 3
            view = m.dirViews[slot]
            channelIndex = page * 4 + slot
            if channelIndex < m.channels.Count()
                channel = m.channels[channelIndex]
                view.dial.Text = channel.dial
                view.dialShadow.Text = channel.dial
                view.logo.Uri = channel.logoUri
                view.name.Text = channel.name
                view.family.Text = channel.family
                view.description.Text = channel.description
                view.stats.Text = channel.stats
                view.group.Visible = true
            else
                view.group.Visible = false
            end if
        end for
        pageCount = Int((m.channels.Count() + 3) / 4)
        m.directoryPage.Text = "PAGE " + (page + 1).ToStr() + " / " + pageCount.ToStr()
        requestDirectorySchedules()
    end if
    updateDirectoryNow()
    updateDirectoryFocus()
end sub

' The live "what is on now" for each visible card, from the same listings the guide uses.
sub updateDirectoryNow()
    for slot = 0 to 3
        channelIndex = m.dirRenderedPage * 4 + slot
        if channelIndex >= m.channels.Count() then return
        channel = m.channels[channelIndex]
        view = m.dirViews[slot]
        title = ""
        if channel.timelineLoaded
            refreshChannelSchedule(channel)
            if channel.now <> invalid
                if channel.now.kind = "video"
                    title = channel.now.title
                else if channel.next <> invalid
                    ' A station break: name the program it leads into.
                    title = channel.next.title
                end if
            end if
        else if channel.schedule <> invalid
            title = "Loading..."
        end if
        if view.nowTitle.Text <> title then view.nowTitle.Text = title
        view.nowLabel.Visible = title <> ""
    end for
end sub

sub updateDirectoryFocus()
    focusSlot = m.dirIndex - m.dirRenderedPage * 4
    for slot = 0 to 3
        view = m.dirViews[slot]
        focused = slot = focusSlot
        if focused
            view.border.Color = "0xFFD740FF"
        else
            view.border.Color = "0x3157A5FF"
        end if
        for buttonIndex = 0 to 1
            button = view.buttons[buttonIndex]
            if focused and buttonIndex = m.dirButton
                button.outline.Color = "0xFFF6A0FF"
                if buttonIndex = 0 then button.face.Color = "0xE0700FFF" else button.face.Color = "0x4A50F0FF"
            else
                button.outline.Color = "0x14153AFF"
                button.face.Color = button.fill
            end if
        end for
    end for
end sub

' Listings for the cards on screen first, then every other channel in dial order,
' so NOW PLAYING fills in across the whole directory.
sub requestDirectorySchedules()
    if m.scheduleTask = invalid then return
    count = m.channels.Count()
    horizon = m.hourStartSec + 14400
    queue = []
    first = m.dirRenderedPage * 4
    for channelIndex = first to first + 3
        if channelIndex < count then addScheduleRequest(queue, channelIndex, true, horizon)
    end for
    for offset = 4 to count - 1
        addScheduleRequest(queue, (first + offset) mod count, false, horizon)
    end for
    m.lastRequestSec = currentEpochSeconds()
    if queue.Count() > 0 then m.scheduleTask.scheduleQueue = queue
end sub

function onDirectoryKey(key as String) as Boolean
    count = m.channels.Count()
    column = m.dirIndex mod 2
    target = m.dirIndex
    button = m.dirButton
    if key = "back" or key = "options"
        closeDirectory()
        showChannel(m.currentIndex, true)
        requestSchedules()
        return true
    else if key = "OK"
        selectDirectoryChannel(m.dirIndex, m.dirButton = 0)
        return true
    else if key = "up"
        target = m.dirIndex - 2
    else if key = "down"
        target = m.dirIndex + 2
        ' The last row can be a single card.
        if target >= count and Int(m.dirIndex / 2) < Int((count - 1) / 2) then target = count - 1
    else if key = "left"
        if button = 1
            button = 0
        else if column = 1
            target = m.dirIndex - 1
            button = 1
        end if
    else if key = "right"
        if button = 0
            button = 1
        else if column = 0 and m.dirIndex + 1 < count
            target = m.dirIndex + 1
            button = 0
        end if
    else if key = "rewind"
        target = m.dirIndex - 4
    else if key = "fastforward"
        target = m.dirIndex + 4
        if target >= count then target = count - 1
    else
        return true
    end if
    if target < 0 or target >= count then return true
    m.dirIndex = target
    m.dirButton = button
    renderDirectory()
    return true
end function

sub selectDirectoryChannel(index as Integer, tuneIn as Boolean)
    closeDirectory()
    showChannel(index, true)
    requestSchedules()
    if tuneIn then tuneInFullscreen(index)
end sub

' Plays the channel full screen now, or as soon as its listings arrive.
sub tuneInFullscreen(index as Integer)
    channel = m.channels[index]
    refreshChannelSchedule(channel)
    if channel.now <> invalid
        enterFullscreen()
    else
        ' Listings not here yet: onScheduleResult goes full screen when they arrive.
        m.pendingTuneId = channel.id
    end if
end sub

' The one recurring job in the app: keeps the clock, the on-air program and the
' progress display following real time, and moves to the next show when a slot ends.
sub onTick()
    m.clock.Mark()
    nowSec = m.clock.AsSeconds()
    m.clock.ToLocalTime()
    minute = m.clock.GetMinutes()
    if minute <> m.lastMinute
        m.lastMinute = minute
        onMinuteChanged(nowSec, m.clock.GetHours(), minute, m.clock.GetSeconds())
    end if
    if not m.active then return
    if m.directoryOpen
        ' The preview is stopped while the directory covers it; only the cards'
        ' NOW PLAYING lines follow the clock.
        updateDirectoryNow()
        ' Retry cards whose listings failed or ran out, as the guide does.
        if nowSec - m.lastRequestSec >= 15
            for slot = 0 to 3
                channelIndex = m.dirRenderedPage * 4 + slot
                if channelIndex < m.channels.Count()
                    if m.channels[channelIndex].now = invalid
                        requestDirectorySchedules()
                        exit for
                    end if
                end if
            end for
        end if
        return
    end if
    if not m.fullscreen and not m.idlePaused and m.lastInputSec > 0
        if nowSec - m.lastInputSec >= m.idleSeconds then pauseIdlePreview()
    end if
    channel = m.channels[m.currentIndex]
    refreshChannelSchedule(channel)
    if airingKey(channel) <> m.infoAiringKey
        updateProgramInfo(channel)
        if Int(m.currentIndex / 8) = m.renderedPage then renderRowCells(m.currentIndex - m.renderedPage * 8, channel)
        if not m.previewPending then startPreview(channel)
        showPlaybackBanner()
    else if m.fullscreen
        if m.playerBanner.Visible then renderPlaybackBanner()
    else
        updateProgress(channel)
    end if
    updateBreakCard(channel)
    if m.previewRetryAt > 0 and nowSec >= m.previewRetryAt and not m.previewPending
        m.previewRetryAt = 0
        startPreview(channel)
    end if
    if m.previewHasStream and not m.previewPending
        if m.previewStartedAt > 0 and nowSec - m.previewStartedAt >= 45
            ' A stream stuck opening never reports an error, so give it a fresh start.
            if m.previewRetries < 2
                m.previewRetries = m.previewRetries + 1
                m.previewKey = ""
                startPreview(channel)
            else
                m.previewStartedAt = 0
                m.previewNotice = "NO SIGNAL"
            end if
        else if m.previewStatic.Visible and not m.staticFading
            ' Some Rokus show the picture while still reporting "buffering". A
            ' position that moves means frames are on screen: never cover them.
            position = m.previewVideo.position
            if m.lastVideoPosition >= 0 and position > m.lastVideoPosition + 0.5 then onStreamPlaying(nowSec)
            m.lastVideoPosition = position
        end if
    end if
    updateTuningBadge(nowSec)
    checkPreviewDrift(nowSec, channel)
    if channel.now = invalid and nowSec - m.lastRequestSec >= 15 then requestSchedules()
end sub

sub onMinuteChanged(nowSec as Integer, localHour as Integer, minute as Integer, second as Integer)
    hours = localHour
    suffix = "AM"
    if hours >= 12 then suffix = "PM"
    hours = hours mod 12
    if hours = 0 then hours = 12
    minutes = minute.ToStr()
    if Len(minutes) = 1 then minutes = "0" + minutes
    ' m.clock is in local time here (onTick converts it before calling).
    dateText = m.clock.GetMonth().ToStr() + "/" + m.clock.GetDayOfMonth().ToStr()
    m.clockLabel.Text = dateText + "   " + hours.ToStr() + ":" + minutes + " " + suffix
    hourStart = nowSec - minute * 60 - second
    if hourStart <> m.hourStartSec
        m.hourStartSec = hourStart
        m.guideTimes.Text = spelunkrHourLabel(localHour)
        m.guideNextHeading.Text = spelunkrHourLabel(localHour + 1)
        m.guideThirdHeading.Text = spelunkrHourLabel(localHour + 2)
        if m.active
            ' Listings hold absolute times, so a new hour only shifts the window.
            renderGuideRows()
            if m.directoryOpen then requestDirectorySchedules() else requestSchedules()
        end if
    else if m.active and not m.fullscreen
        refreshRowHighlights()
    end if
end sub

sub refreshRowHighlights()
    first = m.renderedPage * 8
    for slot = 0 to 7
        channelIndex = first + slot
        if channelIndex >= m.channels.Count() then return
        channel = m.channels[channelIndex]
        refreshChannelSchedule(channel)
        nowStart = -1
        if channel.now <> invalid then nowStart = channel.now.startSec
        if nowStart <> m.rowViews[slot].highlightStart then renderRowCells(slot, channel)
    end for
end sub

function spelunkrHourLabel(hour as Integer) as String
    hour = hour mod 24
    suffix = "AM"
    if hour >= 12 then suffix = "PM"
    hour = hour mod 12
    if hour = 0 then hour = 12
    return hour.ToStr() + ":00 " + suffix
end function

function spelunkrColor(hex as Dynamic) as String
    if type(hex) <> "String" and type(hex) <> "roString" then return "0xFFD740FF"
    if Len(hex) = 6 then hex = "#" + hex
    if Len(hex) = 8 and Left(hex, 2) = "0x" then hex = "#" + Mid(hex, 3, 6)
    if Len(hex) <> 7 then return "0xFFD740FF"
    return "0x" + Mid(hex, 2, 6) + "FF"
end function

function spelunkrDuration(seconds as Integer) as String
    hours = Int(seconds / 3600)
    minutes = Int((seconds mod 3600) / 60)
    secs = seconds mod 60
    mm = minutes.ToStr()
    ss = secs.ToStr()
    if Len(mm) = 1 then mm = "0" + mm
    if Len(ss) = 1 then ss = "0" + ss
    if hours > 0 then return hours.ToStr() + ":" + mm + ":" + ss
    return minutes.ToStr() + ":" + ss
end function
