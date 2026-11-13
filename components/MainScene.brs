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
    ' Text that has to fit a box is measured and sized by fitLabel().
    ' Character widths arrive from the lineup task (setCharWidths).
    m.charWidths = invalid
    m.measureScale = 1.0
    m.progressFill = m.top.FindNode("progressFill")
    m.headerStrip = m.top.FindNode("headerStrip")
    m.stripBg = m.top.FindNode("stripBg")
    m.lineStrip = m.top.FindNode("lineStrip")
    m.stripText = m.top.FindNode("stripText")
    m.nowLine = m.top.FindNode("nowLine")
    m.selectionBar = m.top.FindNode("selectionBar")
    m.selectionEdge = m.top.FindNode("selectionEdge")
    m.rowContent = m.top.FindNode("rowContent")
    m.playerBanner = m.top.FindNode("playerBanner")
    m.playerChannel = m.top.FindNode("playerChannel")
    m.playerLogo = m.top.FindNode("playerLogo")
    m.playerNext = m.top.FindNode("playerNext")
    ' Subtitles: cue lists by subtitle file, the one for the playing program,
    ' and the viewer's on/off choice (off by default, remembered: some tapes
    ' Spelunkr subtitles already have subtitles burned into the picture).
    m.subtitleBox = m.top.FindNode("subtitleBox")
    m.subtitleBack = m.top.FindNode("subtitleBack")
    m.subtitleText = m.top.FindNode("subtitleText")
    m.cues = {}
    m.cues.SetModeCaseSensitive()
    m.activeCues = invalid
    m.activeSubs = invalid
    m.cueIndex = 0
    m.subShown = ""
    m.subtitlesOn = loadSetting("subtitles", "off") = "on"
    m.playerTitle = m.top.FindNode("playerTitle")
    m.playerTime = m.top.FindNode("playerTime")
    m.playerProgressFill = m.top.FindNode("playerProgressFill")
    ' Out-of-sync playback (see "Playing behind the schedule" below).
    m.behind = invalid
    m.syncPanel = m.top.FindNode("syncPanel")
    m.syncTitle = m.top.FindNode("syncTitle")
    m.syncSubtitle = m.top.FindNode("syncSubtitle")
    m.syncHighlight = m.top.FindNode("syncHighlight")
    m.syncItemLabels = []
    syncItems = m.top.FindNode("syncItems")
    for slot = 0 to 6
        label = syncItems.CreateChild("Label")
        label.Translation = [0, slot * 36]
        label.Width = 684
        label.Height = 36
        label.VertAlign = "center"
        label.Font = "font:SmallBoldSystemFont"
        label.Color = "0xE8EAF0FF"
        m.syncItemLabels.Push(label)
    end for
    m.panelOpen = false
    m.panelItems = []
    m.panelIndex = 0
    m.previewProgram = invalid
    m.previewOpenAt = 0

    m.previewVideo.ObserveField("state", "onPreviewState")
    m.previewVideo.notificationInterval = 1
    hideVideoHud(m.previewVideo)
    m.active = false
    m.channels = []
    m.channelIndexById = {}
    m.rowViews = []
    m.currentIndex = 0
    m.renderedPage = -1
    ' The guide is one continuous list that wraps round; rowTop is the channel
    ' in the top row (Scan rolls the same list).
    m.rowTop = 0
    m.rowChannel = []
    m.requestedTop = -1
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
    loadOpenTimes()
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
    buildHintRows()
    buildTimeStrip()
    buildScan()
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
    m.previewTimer.Duration = 0.4
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
    ' An options panel that opened by itself closes after a while; the default stands.
    m.panelTimer = CreateObject("roSGNode", "Timer")
    m.panelTimer.Duration = 12
    m.panelTimer.Repeat = false
    m.panelTimer.ObserveField("fire", "closeSyncPanel")
    m.top.AppendChild(m.panelTimer)
    onTick()
end sub

' The button hints along the bottom: the remote buttons drawn as small icons
' (images/hints, made by tools/build_hint_icons.py), each followed by one word.
sub buildHintRows()
    buildHintRow("remoteHints", [{icons: ["dpad-updown"], text: "CHANNEL"}, {icons: ["dpad-leftright"], text: "PAGE"}, {icons: ["rewind", "forward"], text: "TIME"}, {icons: ["ok"], text: "WATCH"}])
    buildHintRow("directoryHints", [{icons: ["dpad-all"], text: "CHOOSE"}, {icons: ["ok"], text: "SELECT"}, {icons: ["rewind", "forward"], text: "PAGE"}, {icons: ["back"], text: "GUIDE"}])
    buildHintRow("playerHints", [{icons: ["dpad-updown"], text: "CHANNEL"}, {icons: ["playpause"], text: "PAUSE"}, {icons: ["dpad-leftright"], text: "10 SEC"}, {icons: ["ok"], text: "OPTIONS"}, {icons: ["back"], text: "GUIDE"}])
    buildHintRow("syncHints", [{icons: ["dpad-updown"], text: "CHOOSE"}, {icons: ["ok"], text: "SELECT"}, {icons: ["back"], text: "CLOSE"}])
end sub

' Icon widths in the 720p layout (24 px tall; the PNGs are 36 px tall).
function hintIconWidth(name as String) as Integer
    widths = {"dpad-updown": 35, "dpad-leftright": 35, "dpad-all": 24, "ok": 29, "rewind": 24, "forward": 24, "playpause": 24, "back": 24, "star": 24}
    if widths.DoesExist(name) then return widths[name]
    return 24
end function

sub buildHintRow(groupId as String, items as Object)
    group = m.top.FindNode(groupId)
    if group = invalid then return
    x = 0
    for each item in items
        for each icon in item.icons
            poster = group.CreateChild("Poster")
            poster.Uri = "pkg:/images/hints/" + icon + ".png"
            poster.Width = hintIconWidth(icon)
            poster.Height = 24
            poster.Translation = [x, 3]
            x = x + poster.Width + 3
        end for
        label = group.CreateChild("Label")
        label.Font = "font:SmallestBoldSystemFont"
        label.Color = "0xE8EAF0FF"
        label.Height = 30
        label.VertAlign = "center"
        label.Text = item.text
        label.Translation = [x + 4, 0]
        width = label.BoundingRect().width
        if width <= 0 then width = Len(item.text) * 11
        x = x + 4 + width + 22
    end for
end sub

' ---- Subtitles -------------------------------------------------------------------
' Spelunkr publishes timed English lines for some tapes (the Japanese channels).
' The worker marks programs that have them (program.subs) and fetches a tape's
' cues on request; they are drawn here, in step with the video position.

sub setSubtitleSource(program as Object)
    m.activeSubs = invalid
    m.activeCues = invalid
    m.cueIndex = 0
    if program.subs <> invalid
        m.activeSubs = program.subs
        file = program.subs.file
        if m.cues.DoesExist(file)
            m.activeCues = m.cues[file]
        else if m.scheduleTask <> invalid
            m.scheduleTask.cueRequest = {kind: "cues", id: file, manifest: file, priority: true}
        end if
    end if
    updateSubtitleTimer()
end sub

sub updateSubtitleTimer()
    if m.subTimer = invalid then m.subTimer = makeTimer(0.25, true, "onSubtitleTick")
    showing = m.activeCues <> invalid and m.subtitlesOn and m.fullscreen and m.previewHasStream
    if showing
        if m.subTimer.Control <> "start" then m.subTimer.Control = "start"
    else
        m.subTimer.Control = "stop"
        showSubtitle("")
    end if
end sub

sub onSubtitleTick()
    cues = m.activeCues
    if cues = invalid then return
    count = cues.Count()
    positionMs = m.previewVideo.position * 1000
    index = m.cueIndex
    if index >= count then index = count - 1
    if index < 0 then index = 0
    ' Jumped back (seek, restart): search again from the top.
    if count > 0
        if cues[index].a > positionMs then index = 0
    end if
    while index < count
        if cues[index].b > positionMs then exit while
        index = index + 1
    end while
    m.cueIndex = index
    text = ""
    if index < count
        if cues[index].a <= positionMs then text = cues[index].t
    end if
    showSubtitle(text)
end sub

sub showSubtitle(text as String)
    if text = ""
        if m.subtitleBox.Visible then m.subtitleBox.Visible = false
        m.subShown = ""
        return
    end if
    if text <> m.subShown
        m.subShown = text
        m.subtitleText.Text = text
    end if
    height = m.subtitleText.BoundingRect().height
    if height < 30 then height = 34
    m.subtitleBack.Height = height + 12
    ' Above the banner while it shows, near the bottom otherwise.
    bottom = 688
    if m.playerBanner.Visible then bottom = 556
    m.subtitleBox.Translation = [0, bottom - height - 12]
    if not m.subtitleBox.Visible then m.subtitleBox.Visible = true
end sub

function loadSetting(name as String, fallback as String) as String
    value = fallback
    try
        section = CreateObject("roRegistrySection", "spelunkr")
        if section.Exists(name) then value = section.Read(name)
    catch problem
        value = fallback
    end try
    return value
end function

sub saveSetting(name as String, value as String)
    try
        section = CreateObject("roRegistrySection", "spelunkr")
        section.Write(name, value)
        section.Flush()
    catch problem
        print "Setting not saved: "; problem.message
    end try
end sub

' Spelunkr published new schedules (seen by the worker's heartbeat): channels
' whose version changed get rebuilt from their new schedule.
sub applyLineupUpdate(updates as Dynamic)
    if type(updates) <> "roArray" then return
    changed = 0
    for each update in updates
        if m.channelIndexById.DoesExist(update.id) and update.schedule <> invalid
            channel = m.channels[m.channelIndexById[update.id]]
            old = channel.schedule
            different = old = invalid
            if not different then different = old.version <> update.schedule.version or old.epochSec <> update.schedule.epochSec or old.startIndex <> update.schedule.startIndex
            if different
                channel.schedule = update.schedule
                channel.timelineEndSec = 0
                changed = changed + 1
            end if
        end if
    end for
    print "Lineup update: "; changed; " channels have a new schedule"
    if changed > 0 then requestSchedules()
end sub

' The Video node keeps its own HUD (a clock, the trick-play bar, "Loading" and
' "Retrieving" bars) laid out for full screen even with enableUI off. While a
' stream loads it briefly showed its clock, which peeked out from behind the
' info panel at the right edge of the guide ("8:24 pm"). The app draws its own
' static, TUNING IN badge and banner, so the built-in HUD is hidden for good.
sub hideVideoHud(video as Object)
    ' The HUD group is only built once a stream is set, and the firmware turns
    ' its clock on and off by itself, so this runs at every open and state
    ' change and hides the whole group (every child except VideoBackground).
    for index = 0 to video.getChildCount() - 1
        child = video.getChild(index)
        if child.subtype() <> "VideoBackground" and child.opacity <> 0 then child.opacity = 0
    end for
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
    setCharWidths(m.task.charWidths)
    for index = 0 to m.channels.Count() - 1
        m.channelIndexById[m.channels[index].id] = index
    end for
    ' The finished task would otherwise keep a second copy of the whole lineup.
    subtitlesPath = m.task.subtitlesPath
    m.task.UnobserveField("status")
    m.task.UnobserveField("complete")
    m.task = invalid
    m.scheduleTask = CreateObject("roSGNode", "GuideTask")
    m.scheduleTask.functionName = "runScheduleWorker"
    m.scheduleTask.channelCount = m.channels.Count()
    m.scheduleTask.subtitlesPath = subtitlesPath
    m.scheduleTask.ObserveField("scheduleBatch", "onScheduleBatch")
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
    if m.scanOn <> true
        ' Bring a channel that is not on screen (a deep link, the directory) to the top.
        slot = slotOfChannel(index)
        if slot < 0 or slot > 7
            m.rowTop = index
            renderGuideRows()
        end if
    end if
    updateSelection()
    ' New rows on screen: ask for their listings first (debounced while scrolling).
    if m.rowTop <> m.requestedTop or m.scanOn = true
        m.scheduleLoadTimer.Control = "stop"
        m.scheduleLoadTimer.Control = "start"
    end if
    if m.scanOn <> true
        if channel.timelineLoaded then m.status.Text = "" else m.status.Text = "Loading listings..."
    end if
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
        fitLabel(m.nowDescription, programDescription(channel, program), "font:SmallSystemFont", [22, 20, 19, 18, 17], 650, 112)
        nextTitle = "UP NEXT"
        if channel.next <> invalid then nextTitle = nextTitle + "  " + channel.next.title
        fitLabel(m.nextTitle, nextTitle, "font:SmallSystemFont", [22, 20, 19, 18, 17], 650, 52)
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
    if program.subs <> invalid then meta = meta + "  ·  CC"
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
    for slot = 0 to 8
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
        m.rowViews.Push({group: row, logo: logo, dial: dial, dialShadow: dialShadow, name: name, cells: [], highlightStart: -1})
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

' Eight rows on screen and a ninth below, from rowTop round the lineup, so
' 02 follows 600 with no empty rows anywhere.
sub renderGuideRows()
    renderScanRows()
end sub

' Puts a channel (or nothing, for -1) into one row slot.
sub fillRow(slot as Integer, channelIndex as Integer)
    view = m.rowViews[slot]
    placeRow(view, slot)
    if channelIndex >= 0
        channel = m.channels[channelIndex]
        view.logo.Uri = channel.logoUri
        view.dial.Text = channel.dial
        view.dialShadow.Text = channel.dial
        view.name.Text = channel.name
        renderRowCells(slot, channel)
        view.group.Visible = true
        view.bgRow.Visible = true
        view.textRow.Visible = true
    else
        view.group.Visible = false
        view.bgRow.Visible = false
        view.textRow.Visible = false
        view.shade.Visible = false
    end if
end sub

sub placeRow(view as Object, slot as Integer)
    y = slot * 35
    view.group.Translation = [0, y]
    view.bgRow.Translation = [0, y]
    view.textRow.Translation = [0, y]
end sub

function slotOfChannel(channelIndex as Integer) as Integer
    if m.rowChannel = invalid then return -1
    for slot = 0 to m.rowChannel.Count() - 1
        if m.rowChannel[slot] = channelIndex then return slot
    end for
    return -1
end function

' ---- Scan mode ---------------------------------------------------------------
' Play/Pause in the guide: the listings roll up one channel at a time through
' the whole lineup, like the old cable guide channels, while the preview hops between channels like an old TV's SCAN button. Every 45 s the
' channel at the top becomes the featured one: the preview tunes to it and the
' info panel shows it. Up/Down roll by hand and pause the roll; it resumes 10 s
' after the last press. OK watches the featured channel; Play/Pause again or
' Back returns to the normal guide.

sub buildScan()
    m.scanOn = false
    m.rowTop = 0
    m.scanFrozen = false
    m.scanManual = false
    m.rollGroup = m.top.FindNode("rollGroup")
    m.remoteHints = m.top.FindNode("remoteHints")
    m.scanFaceTop = m.top.FindNode("scanFaceTop")
    m.scanFaceBottom = m.top.FindNode("scanFaceBottom")
    m.scanIcon = m.top.FindNode("scanIcon")
    m.rollAnim = CreateObject("roSGNode", "Animation")
    m.rollAnim.Duration = 0.8
    m.rollAnim.Repeat = false
    m.rollAnim.EaseFunction = "inOutQuad"
    m.rollInterp = m.rollAnim.CreateChild("Vector2DFieldInterpolator")
    m.rollInterp.Key = [0.0, 1.0]
    m.rollInterp.KeyValue = [[0, 0], [0, -35]]
    m.rollInterp.FieldToInterp = "rollGroup.translation"
    m.top.AppendChild(m.rollAnim)
    m.rollAnim.ObserveField("state", "onRollState")
    m.rollTimer = makeTimer(4, true, "rollStep")
    m.featureTimer = makeTimer(45, true, "featureTopChannel")
    m.scanResumeTimer = makeTimer(10, false, "resumeScanRoll")
end sub

function makeTimer(seconds as Float, repeating as Boolean, callback as String) as Object
    timer = CreateObject("roSGNode", "Timer")
    timer.Duration = seconds
    timer.Repeat = repeating
    timer.ObserveField("fire", callback)
    m.top.AppendChild(timer)
    return timer
end function

sub enterScan()
    if not m.active or m.directoryOpen or m.fullscreen or m.channels.Count() < 9 then return
    m.scanOn = true
    m.scanFrozen = false
    m.scanManual = false
    ' Scan starts rolling from the rows already on screen.
    renderScanRows()
    ' The button lights orange while Scan is on; that is the only marker.
    m.scanFaceTop.Color = "0xD2640FFF"
    m.scanFaceBottom.Color = "0xB0480AFF"
    ' Play turns into pause on the button while Scan runs.
    m.scanIcon.Uri = "pkg:/images/pause.png"
    m.status.Text = ""
    m.rollTimer.Control = "start"
    m.featureTimer.Control = "start"
end sub

sub exitScan()
    if m.scanOn <> true then return
    m.scanOn = false
    m.rollTimer.Control = "stop"
    m.featureTimer.Control = "stop"
    m.scanResumeTimer.Control = "stop"
    m.rollAnim.Control = "stop"
    m.rollGroup.Translation = [0, 0]
    m.scanFaceTop.Color = "0x2B2FC4FF"
    m.scanFaceBottom.Color = "0x2226A0FF"
    m.scanIcon.Uri = "pkg:/images/arrow-right.png"
    m.status.Text = ""
    ' Keep the rows where Scan left them; the highlighted channel must be on screen.
    slot = slotOfChannel(m.currentIndex)
    if slot < 0 or slot > 7 then m.rowTop = m.currentIndex
    renderGuideRows()
end sub

' Nine rows from the top channel, wrapping round the lineup.
sub renderScanRows()
    if m.channels.Count() = 0 then return
    count = m.channels.Count()
    m.rowChannel = []
    for slot = 0 to m.rowViews.Count() - 1
        m.rowChannel.Push((m.rowTop + slot) mod count)
    end for
    for slot = 0 to m.rowViews.Count() - 1
        fillRow(slot, m.rowChannel[slot])
    end for
    m.rollGroup.Translation = [0, 0]
    updateSelection()
end sub

sub rollStep()
    if m.scanOn <> true or m.scanFrozen or m.scanManual then return
    if m.fullscreen or m.directoryOpen or m.idlePaused then return
    if m.rollAnim.State = "running" then return
    m.rollAnim.Control = "start"
end sub

sub onRollState()
    if m.rollAnim.State = "stopped" and m.scanOn = true then shiftRows(1)
end sub

' Moves the lineup one channel: the row that left the top is reused for the
' channel arriving at the bottom (or the reverse), so only one row is drawn.
sub shiftRows(direction as Integer)
    count = m.channels.Count()
    if direction > 0
        m.rowTop = (m.rowTop + 1) mod count
        view = m.rowViews.Shift()
        m.rowViews.Push(view)
        m.rowChannel.Shift()
        m.rowChannel.Push((m.rowTop + m.rowViews.Count() - 1) mod count)
        changed = m.rowViews.Count() - 1
    else
        m.rowTop = (m.rowTop - 1 + count) mod count
        view = m.rowViews.Pop()
        m.rowViews.Unshift(view)
        m.rowChannel.Pop()
        m.rowChannel.Unshift(m.rowTop)
        changed = 0
    end if
    for slot = 0 to m.rowViews.Count() - 1
        placeRow(m.rowViews[slot], slot)
    end for
    m.rollGroup.Translation = [0, 0]
    fillRow(changed, m.rowChannel[changed])
    updateSelection()
    updateStickyTitles()
end sub

' Every 45 s: the channel now at the top is featured in the preview and panel.
sub featureTopChannel()
    if m.scanOn <> true or m.scanFrozen or m.scanManual then return
    if m.fullscreen or m.directoryOpen or m.idlePaused then return
    showChannel(m.rowTop, true)
end sub

' Up/Down in Scan: roll by hand, feature the top channel, pause the roll.
sub scanManualStep(steps as Integer)
    m.rollAnim.Control = "stop"
    m.scanManual = true
    if steps > 0 then direction = 1 else direction = -1
    for count = 1 to Abs(steps)
        shiftRows(direction)
    end for
    showChannel(m.rowTop, true)
    m.status.Text = "ROLL RESUMES IN 10s"
    m.scanResumeTimer.Control = "stop"
    m.scanResumeTimer.Control = "start"
end sub

sub resumeScanRoll()
    m.scanManual = false
    if m.scanOn = true then m.status.Text = ""
end sub

sub updateSelection()
    slot = slotOfChannel(m.currentIndex)
    show = slot >= 0 and slot <= 7
    m.selectionBar.Visible = show
    m.selectionEdge.Visible = show
    if not show then return
    m.selectionBar.Translation = [0, slot * 35]
    m.selectionEdge.Translation = [0, slot * 35]
end sub

' Sets a label's text at the largest of the given font sizes at which the whole
' text wraps into width x height, measuring words with the system font. A label's
' own font is sized with label.Font.Size (a separate Font node with a "font:"
' Uri did not change the size on the TV).
sub fitLabel(label as Object, text as String, fontUri as String, sizes as Object, width as Integer, height as Integer)
    chosen = sizes[sizes.Count() - 1]
    for each size in sizes
        allowed = Int(height / lineHeightFor(size))
        if allowed < 1 then allowed = 1
        if wrappedLineCount(text, size, width) <= allowed
            chosen = size
            exit for
        end if
    end for
    lines = Int(height / lineHeightFor(chosen))
    if lines < 1 then lines = 1
    label.Font = fontUri
    label.Font.Size = chosen
    label.Wrap = lines > 1
    label.MaxLines = lines
    label.Text = text
end sub

' Measured on device: SmallSystemFont (22) wraps at a 32 px line pitch.
function lineHeightFor(size as Integer) as Integer
    return Int(size * 1.45 + 0.99)
end function

' Takes the task's width table and calibrates it against a line seen on the TV:
' in SmallSystemFont (22) this sentence drew 560 px wide in the directory.
sub setCharWidths(widths as Dynamic)
    if type(widths) <> "roAssociativeArray" or widths.Count() < 90 then return
    m.charWidths = widths
    m.measureScale = 1.0
    sampleWidth = textWidth22("Wake up, pour the cereal, watch cartoons. Actual Saturday")
    if sampleWidth > 0 then m.measureScale = 560.0 / sampleWidth
    if m.measureScale < 0.5 or m.measureScale > 2.0
        m.measureScale = 1.0
    end if
    print "Text measure scale: "; m.measureScale
end sub

' Width of text in the system font at size 22, before calibration.
function textWidth22(text as String) as Float
    total = 0.0
    for position = 1 to Len(text)
        key = Asc(Mid(text, position, 1)).ToStr()
        if m.charWidths.DoesExist(key) then total = total + m.charWidths[key] else total = total + 11
    end for
    return total
end function

function wrappedLineCount(text as String, size as Integer, width as Integer) as Integer
    if text = "" then return 1
    ' A small margin, since the label's own wrapping may break a little earlier.
    usable = width * 0.96
    if m.charWidths = invalid
        ' No font metrics: about 0.47 em per character in the system font.
        perLine = Int(usable / (size * 0.47))
        if perLine < 1 then perLine = 1
        return Int((Len(text) + perLine - 1) / perLine)
    end if
    factor = m.measureScale * size / 22.0
    spaceWidth = textWidth22(" ") * factor
    lines = 1
    lineWidth = 0.0
    for each word in text.Split(" ")
        wordWidth = textWidth22(word) * factor
        if lineWidth = 0
            lineWidth = wordWidth
        else if lineWidth + spaceWidth + wordWidth <= usable
            lineWidth = lineWidth + spaceWidth + wordWidth
        else
            lines = lines + 1
            lineWidth = wordWidth
        end if
    end for
    return lines
end function

' ---- Scrolling time strip ----------------------------------------------------
' The listings sit on one strip laid out in absolute time from m.baseSec (an
' hour before the current hour) and drawn 8 hours wide. The 3-hour window
' (891 px from x 306) looks at part of it: live, half an hour of past and two
' and a half ahead, with the yellow now line fixed there while the strip moves
' left 1 px about every 12 s. Whole pixels only, so text never shimmers.
' REW / FF move the window by half an hour to look back or ahead.

sub buildTimeStrip()
    m.axisX = 306
    m.pxPerSec = 891.0 / 10800.0
    m.baseSec = 0
    m.viewOffsetPx = -1
    m.browseOffsetSec = 0
    m.nowPx = -1
    m.labelClock = CreateObject("roDateTime")
    ' Half-hour dividers under the cells; hours a little brighter.
    dividerLayer = m.stripBg.CreateChild("Group")
    m.dividers = []
    m.headings = []
    for index = 0 to 16
        divider = dividerLayer.CreateChild("Rectangle")
        divider.Width = 1
        divider.Height = 315
        m.dividers.Push(divider)
        tick = m.headerStrip.CreateChild("Rectangle")
        tick.Width = 1
        tick.Height = 28
        tick.Color = "0x7788BB66"
        heading = m.headerStrip.CreateChild("Label")
        heading.Width = 140
        heading.Height = 24
        heading.Translation = [0, 2]
        heading.Font = "font:SmallBoldSystemFont"
        heading.Color = "0xFFD740FF"
        m.headings.Push({tick: tick, label: heading})
    end for
    for slot = 0 to 8
        view = m.rowViews[slot]
        view.bgRow = m.stripBg.CreateChild("Group")
        view.bgRow.Translation = [0, slot * 35]
        view.textRow = m.stripText.CreateChild("Group")
        view.textRow.Translation = [0, slot * 35]
        view.nowCellX = -1
        view.nowCellRight = -1
        view.arrow = view.textRow.CreateChild("Poster")
        view.arrow.Uri = "pkg:/images/arrow-left.png"
        view.arrow.Width = 8
        view.arrow.Height = 14
        view.arrow.BlendColor = "0xE8EAF0FF"
        view.arrow.Visible = false
    end for
    ' The elapsed part of each now-playing cell, a shade darker. One per row,
    ' above the cells.
    shadeLayer = m.stripBg.CreateChild("Group")
    for slot = 0 to 8
        shade = shadeLayer.CreateChild("Rectangle")
        shade.Translation = [0, slot * 35 + 1]
        shade.Height = 33
        shade.Width = 0
        shade.Color = "0x00000048"
        shade.Visible = false
        m.rowViews[slot].shade = shade
    end for
    m.nowMarker = m.headerStrip.CreateChild("Poster")
    m.nowMarker.Uri = "pkg:/images/now-marker.png"
    m.nowMarker.Width = 12
    m.nowMarker.Height = 8
    m.nowMarker.BlendColor = "0xFFD740FF"
    m.nowMarker.Translation = [0, 20]
    ' A short glide for REW / FF and the return to now.
    m.stripGlide = CreateObject("roSGNode", "Animation")
    m.stripGlide.Duration = 0.4
    m.stripGlide.Repeat = false
    m.stripGlide.EaseFunction = "outCubic"
    m.glideTargets = []
    for each node in [m.stripBg, m.lineStrip, m.stripText, m.headerStrip]
        interp = m.stripGlide.CreateChild("Vector2DFieldInterpolator")
        interp.Key = [0.0, 1.0]
        interp.FieldToInterp = node.Id + ".translation"
        m.glideTargets.Push(interp)
    end for
    m.top.AppendChild(m.stripGlide)
    m.stripGlide.ObserveField("state", "onStripGlideState")
    m.browseTimer = CreateObject("roSGNode", "Timer")
    m.browseTimer.Duration = 10
    m.browseTimer.Repeat = false
    m.browseTimer.ObserveField("fire", "returnToNow")
    m.top.AppendChild(m.browseTimer)
end sub

function stripX(sec as Integer) as Integer
    return Int((sec - m.baseSec) * m.pxPerSec)
end function

' Lays the strip out again from a new base: the hour before the current hour.
sub rebaseTimeStrip()
    m.baseSec = m.hourStartSec - 3600
    for index = 0 to m.dividers.Count() - 1
        sec = m.baseSec + index * 1800
        x = stripX(sec)
        divider = m.dividers[index]
        divider.Translation = [x - 1, 0]
        if index mod 2 = 0 then divider.Color = "0x7788BB66" else divider.Color = "0x7788BB33"
        heading = m.headings[index]
        heading.tick.Translation = [x - 1, 0]
        heading.label.Translation = [x + 7, 2]
        heading.label.Text = localTimeLabel(sec)
    end for
    m.viewOffsetPx = -1
    m.nowPx = -1
end sub

function localTimeLabel(sec as Integer) as String
    m.labelClock.FromSeconds(sec)
    m.labelClock.ToLocalTime()
    hour = m.labelClock.GetHours()
    minute = m.labelClock.GetMinutes()
    suffix = "AM"
    if hour >= 12 then suffix = "PM"
    hour = hour mod 12
    if hour = 0 then hour = 12
    minutes = minute.ToStr()
    if Len(minutes) = 1 then minutes = "0" + minutes
    return hour.ToStr() + ":" + minutes + " " + suffix
end function

function viewStartSec(nowSec as Integer) as Integer
    return nowSec - 1800 + m.browseOffsetSec
end function

' Called every second: moves the now line and the strip when a whole pixel
' has passed. glide = true eases to the new place (REW / FF, back to now).
sub updateTimeStrip(nowSec as Integer, glide as Boolean)
    if m.baseSec = 0 then return
    nowPx = stripX(nowSec)
    offsetPx = stripX(viewStartSec(nowSec))
    if nowPx = m.nowPx and offsetPx = m.viewOffsetPx and not glide then return
    m.nowPx = nowPx
    m.nowLine.Translation = [nowPx - 1, 0]
    m.nowMarker.Translation = [nowPx - 6, 20]
    target = [m.axisX - offsetPx, 0]
    if glide and m.viewOffsetPx >= 0
        m.stripGlide.Control = "stop"
        for each interp in m.glideTargets
            interp.KeyValue = [[m.axisX - m.viewOffsetPx, 0], target]
        end for
        m.viewOffsetPx = offsetPx
        m.stripGlide.Control = "start"
    else
        m.viewOffsetPx = offsetPx
        m.stripBg.Translation = target
        m.lineStrip.Translation = target
        m.stripText.Translation = target
        m.headerStrip.Translation = target
        updateStickyTitles()
    end if
    updateElapsedShading(nowSec)
end sub

sub onStripGlideState()
    if m.stripGlide.State = "stopped" then updateStickyTitles()
end sub

' A program that started before the window shows its title from the window's
' left edge, after a small arrow, like the old cable guide channel.
sub updateStickyTitles()
    left = m.viewOffsetPx
    lastSlot = m.rowViews.Count() - 1
    ' The window starts half an hour before now, not on a half hour, so the
    ' columns at its edges are partial. A time label shows only when it fits
    ' whole; a cut-off "3:30 P" at the edge reads as a broken column.
    for each heading in m.headings
        labelX = heading.label.Translation[0]
        heading.label.Visible = labelX >= left + 2 and labelX + 92 <= left + 891
    end for
    for slot = 0 to lastSlot
        view = m.rowViews[slot]
        arrowAt = -1
        for each cell in view.cells
            if cell.used and cell.title <> invalid
                labelX = cell.x + 5
                if cell.x < left and cell.right > left
                    labelX = left + 16
                    arrowAt = left + 4
                end if
                width = cell.right - labelX - 4
                show = width >= 30
                cell.title.Translation = [labelX, 1]
                cell.length.Translation = [labelX, 20]
                if show
                    cell.title.Width = width
                    cell.length.Width = width
                end if
                cell.title.Visible = show
                cell.length.Visible = show
            end if
        end for
        if arrowAt >= 0
            view.arrow.Translation = [arrowAt, 10]
            view.arrow.Visible = true
        else
            view.arrow.Visible = false
        end if
    end for
end sub

' Everything left of the now line has aired: every row is shaded up to it,
' whether a program, a station break or a commercial is on, so each row shows
' how far the broadcast has got. The strip clip trims it to the window.
sub updateElapsedShading(nowSec as Integer)
    nowPx = stripX(nowSec)
    for slot = 0 to m.rowViews.Count() - 1
        view = m.rowViews[slot]
        if nowPx > 0
            view.shade.Translation = [0, slot * 35 + 1]
            view.shade.Width = nowPx
            view.shade.Visible = view.bgRow.Visible
        else
            view.shade.Visible = false
        end if
    end for
end sub

' REW / FF in the guide: half an hour back or ahead, within the listings.
sub browseTime(deltaSec as Integer)
    nowSec = currentEpochSeconds()
    offset = m.browseOffsetSec + deltaSec
    ' Not before the start of the strip, not past the listings fetched (6 hours
    ' from the top of the hour).
    earliest = m.baseSec - (nowSec - 1800)
    latest = (m.hourStartSec + 21600 - 10800) - (nowSec - 1800)
    if offset < earliest then offset = earliest
    if offset > latest then offset = latest
    if offset = m.browseOffsetSec then return
    m.browseOffsetSec = offset
    updateTimeStrip(nowSec, true)
    if offset = 0
        m.browseTimer.Control = "stop"
        m.status.Text = ""
    else
        showBrowseStatus()
        m.browseTimer.Control = "stop"
        m.browseTimer.Control = "start"
    end if
end sub

sub showBrowseStatus()
    startSec = viewStartSec(currentEpochSeconds())
    m.status.Text = "VIEWING " + localTimeLabel(startSec) + " - " + localTimeLabel(startSec + 10800)
end sub

sub returnToNow()
    if m.browseOffsetSec = 0 then return
    m.browseOffsetSec = 0
    m.status.Text = ""
    updateTimeStrip(currentEpochSeconds(), true)
end sub

sub renderRowCells(slot as Integer, channel as Object)
    view = m.rowViews[slot]
    refreshChannelSchedule(channel)
    nowStart = -1
    if channel.now <> invalid then nowStart = channel.now.startSec
    view.highlightStart = nowStart
    view.nowCellX = -1
    view.nowCellRight = -1
    used = 0
    stripEnd = m.baseSec + 28800
    ' Shows under about 10 minutes are too narrow to read, so a run of them that
    ' follow each other (only up-next cards between) is drawn as one cell:
    ' the first title, then "N SHOWS" and the run's total time.
    narrowPixels = 84
    pending = invalid
    for each item in channel.timeline
        if item.startSec >= stripEnd then exit for
        x = stripX(item.startSec)
        right = stripX(item.startSec + item.duration)
        ' Breaks stay as gaps between programs, as on a printed guide.
        if right > 0 and right - x >= 2 and item.kind = "video"
            narrow = item.duration * m.pxPerSec < narrowPixels
            isNow = item.startSec = nowStart
            joined = false
            if pending <> invalid and narrow and pending.narrow
                gap = item.startSec - pending.endSec
                if gap >= -5 and gap <= 45 then joined = true
            end if
            if joined
                pending.right = right
                pending.count = pending.count + 1
                pending.seconds = pending.seconds + item.duration
                pending.endSec = item.startSec + item.duration
                if isNow then pending.isNow = true
            else
                if pending <> invalid then used = drawGuideCell(view, used, pending)
                if used >= 70
                    pending = invalid
                    exit for
                end if
                pending = {x: x, right: right, count: 1, title: item.title, seconds: item.duration, endSec: item.startSec + item.duration, narrow: narrow, isNow: isNow}
            end if
        end if
    end for
    if pending <> invalid and used < 70 then used = drawGuideCell(view, used, pending)
    for index = used to view.cells.Count() - 1
        cell = view.cells[index]
        cell.used = false
        cell.rect.Visible = false
        if cell.title <> invalid
            cell.title.Visible = false
            cell.length.Visible = false
        end if
    end for
    updateStickyTitles()
    updateElapsedShading(currentEpochSeconds())
end sub


' Draws one guide cell and returns the number of cells now in use.
function drawGuideCell(view as Object, used as Integer, span as Object) as Integer
    cell = rowCell(view, used)
    cellWidth = span.right - span.x
    cell.used = true
    cell.x = span.x
    cell.right = span.right
    cell.rect.Translation = [span.x, 1]
    cell.rect.Width = cellWidth
    ' One color for every program: the now line splits each row into dimmed
    ' (aired, under the shade) and bright (still to come).
    cell.rect.Color = "0x344A91FF"
    if span.isNow
        view.nowCellX = span.x
        view.nowCellRight = span.right
    end if
    if cell.title = invalid
        ' Smaller than the panel text, so more of each title fits a cell.
        cell.title = addGuideLabel(view.textRow, 0, 1, 0, 19, "font:SmallSystemFont", "0xE8EAF0FF")
        cell.title.Font.Size = 17
        cell.length = addGuideLabel(view.textRow, 0, 20, 0, 13, "font:SmallestSystemFont", "0xC7D2F2FF")
        cell.length.Font.Size = 12
    end if
    cell.title.Text = span.title
    if span.count > 1
        lengthText = span.count.ToStr() + " SHOWS"
        if cellWidth >= 150 then lengthText = lengthText + "  ·  " + spelunkrDuration(span.seconds)
        cell.length.Text = lengthText
    else
        cell.length.Text = spelunkrDuration(span.seconds)
    end if
    cell.rect.Visible = true
    return used + 1
end function

function rowCell(view as Object, index as Integer) as Object
    if index < view.cells.Count() then return view.cells[index]
    rect = view.bgRow.CreateChild("Rectangle")
    rect.Height = 33
    cell = {rect: rect, title: invalid, length: invalid, used: false, x: 0, right: 0}
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
    m.requestedTop = m.rowTop
    m.lastRequestSec = currentEpochSeconds()
    ' The worker returns six hours, so channels only refresh every couple of hours.
    horizon = m.hourStartSec + 14400
    queue = []
    ' First the selected channel and the rows on screen (the list scrolls and
    ' wraps, so these are not a fixed page), then the rest outward from them.
    requested = {}
    addScheduleRequest(queue, m.currentIndex, true, horizon)
    requested[m.currentIndex.ToStr()] = true
    for slot = 0 to 7
        if slot < m.rowChannel.Count()
            channelIndex = m.rowChannel[slot]
            if channelIndex >= 0 and not requested.DoesExist(channelIndex.ToStr())
                addScheduleRequest(queue, channelIndex, true, horizon)
                requested[channelIndex.ToStr()] = true
            end if
        end if
    end for
    for distance = 0 to count - 1
        for each channelIndex in [(m.rowTop + 8 + distance) mod count, ((m.rowTop - 1 - distance) mod count + count) mod count]
            if not requested.DoesExist(channelIndex.ToStr())
                addScheduleRequest(queue, channelIndex, false, horizon)
                requested[channelIndex.ToStr()] = true
            end if
        end for
    end for
    if queue.Count() > 0 then m.scheduleTask.scheduleQueue = queue
end sub

sub addScheduleRequest(queue as Object, channelIndex as Integer, priority as Boolean, horizon as Integer)
    channel = m.channels[channelIndex]
    if channel.schedule = invalid then return
    ' A delayed viewer on this channel needs listings from where they are.
    fromSec = invalid
    if channelIndex = m.currentIndex and m.behind <> invalid
        if m.behind.policy = "delayed" then fromSec = m.behind.event.startSec - 600
    end if
    reachesBack = true
    if fromSec <> invalid
        reachesBack = false
        if channel.timeline.Count() > 0 then reachesBack = channel.timeline[0].startSec <= fromSec
    end if
    if channel.timelineLoaded and channel.timelineEndSec >= horizon and reachesBack then return
    schedule = channel.schedule
    request = {kind: "manifest", id: channel.id, manifest: schedule.manifest, details: schedule.details, version: schedule.version, epochSec: schedule.epochSec, epochMsRem: schedule.epochMsRem, startIndex: schedule.startIndex, priority: priority}
    if fromSec <> invalid then request.fromSec = fromSec
    queue.Push(request)
end sub

' The worker sends its results in batches (see workerFlush in GuideTask.brs).
sub onScheduleBatch(event as Object)
    batch = event.GetData()
    if type(batch) <> "roArray" then return
    for each result in batch
        handleScheduleResult(result)
    end for
end sub

sub handleScheduleResult(result as Dynamic)
    if type(result) <> "roAssociativeArray" then return
    if result.DoesExist("lineupUpdate")
        applyLineupUpdate(result.lineupUpdate)
        return
    end if
    if result.DoesExist("cuesFor")
        m.cues[result.cuesFor] = result.cues
        if m.activeSubs <> invalid
            if m.activeSubs.file = result.cuesFor then m.activeCues = result.cues
        end if
        updateSubtitleTimer()
        return
    end if
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
    resultSlot = slotOfChannel(channelIndex)
    if resultSlot >= 0 then renderRowCells(resultSlot, channel)
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
    hideVideoHud(m.previewVideo)
    state = m.previewVideo.state
    if m.previewKey = "" or not m.previewHasStream then return
    nowSec = currentEpochSeconds()
    if state = "playing"
        onStreamPlaying(nowSec)
    else if state = "error"
        print "Preview error for "; m.previewKey; ": "; m.previewVideo.errorCode; " "; m.previewVideo.errorMsg; " "; m.previewVideo.errorStr
        if handleLimitError() then return
        ' A direct server link that fails is not used again; retries go through archive.org.
        retryDelay = 2
        if m.previewDirectId <> ""
            m.directFailed[m.previewDirectId] = true
            ' The archive.org link is a different route, so try it straight away.
            retryDelay = 1
        end if
        showStatic()
        m.previewStartedAt = 0
        if m.previewRetries < 2
            m.previewRetries = m.previewRetries + 1
            m.previewKey = ""
            m.previewRetryAt = nowSec + retryDelay
        else
            m.previewNotice = "NO SIGNAL"
        end if
    else if state = "finished"
        if m.behind <> invalid
            if m.behind.policy <> "switch"
                behindProgramEnded()
                return
            end if
        end if
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
    saveOpenTimes()
end sub

' What this TV learned about open times is kept between launches, so the first
' stream of a session already starts at the right live point.
sub loadOpenTimes()
    try
        section = CreateObject("roRegistrySection", "spelunkr")
        base = Val(section.Read("openBaseSec"))
        rate = Val(section.Read("openBytesPerSec"))
        if base >= 0.5 and base <= 8 then m.openBaseSec = base
        if rate >= 200000 and rate <= 20000000 then m.openBytesPerSec = rate
    catch problem
        print "Open times not loaded: "; problem.message
    end try
end sub

sub saveOpenTimes()
    try
        section = CreateObject("roRegistrySection", "spelunkr")
        section.Write("openBaseSec", Str(m.openBaseSec).Trim())
        section.Write("openBytesPerSec", Str(m.openBytesPerSec).Trim())
        section.Flush()
    catch problem
        print "Open times not saved: "; problem.message
    end try
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
    if m.behind <> invalid and not m.fullscreen and not m.previewStatic.Visible
        m.previewBadgeText.Text = "OUT OF SYNC  ·  ROKU PLAYER LIMIT"
        m.previewBadge.Visible = true
        return
    end if
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
    ' Out of sync on purpose: never pull the picture back to the live point.
    if m.behind <> invalid then return
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

' ---- Playing behind the schedule -------------------------------------------
' Some tapes (YouCut edits on SATURDAY MORNING) store their length in a way the
' Roku player cuts to 32 bits, so it cannot open or jump past a point inside
' them (36:26 into one 4-hour tape). Tuning in later fails. Instead of NO
' SIGNAL, the tape plays from the furthest point it can, out of sync with the
' website, and the viewer chooses what happens next:
'   policy "switch"  - cut over to the live program when the schedule moves on
'   policy "finish"  - play this program to its end, then rejoin live
'   policy "delayed" - keep playing the channel's lineup in order, behind live
' m.behind: {event, policy, limit, offered, lastPos, cardStartSec, waiting, reason}

function playingProgram(channel as Object) as Dynamic
    if m.behind <> invalid then return m.behind.event
    return channel.now
end function

function behindDelaySec() as Integer
    if m.behind = invalid then return 0
    event = m.behind.event
    nowSec = currentEpochSeconds()
    if event.kind = "card"
        played = event.startSec + (nowSec - m.behind.cardStartSec)
    else
        position = m.behind.lastPos
        if m.previewHasStream and m.previewVideo.position > 0 then position = Int(m.previewVideo.position)
        played = event.startSec + (position - event.inS)
    end if
    delay = nowSec - played
    if delay < 0 then delay = 0
    return delay
end function

function behindLabel() as String
    return "OUT OF SYNC  ·  " + spelunkrDuration(behindDelaySec()) + " BEHIND"
end function

' Where a file with a microsecond timescale wraps for the Roku player: its
' length in microseconds, kept to 32 bits. Measured on a Roku TV, the result
' matched to the second on two tapes (2186 s and 3020 s).
function rokuSeekLimit(program as Object) as Integer
    fileSec = m.previewVideo.duration
    if fileSec = invalid or fileSec <= 0 then fileSec = program.inS + program.duration
    micro = fileSec * 1000000#
    span = 4294967296#
    if micro < span then return -1
    wraps = Int(micro / span)
    rest = micro - wraps * span
    return Int(rest / 1000000#)
end function

' The player refused the open point. If it is the Roku length limit, reopen
' the same tape as far in as it allows. Returns true when that was handled.
function handleLimitError() as Boolean
    if m.previewProgram = invalid then return false
    detail = ""
    if m.previewVideo.errorStr <> invalid then detail = LCase(m.previewVideo.errorStr)
    if Instr(1, detail, "sample number too large") = 0 and Instr(1, detail, "demux get sample error") = 0 then return false
    program = m.previewProgram
    if program.kind = "card" then return false
    limit = rokuSeekLimit(program)
    same = false
    if m.behind <> invalid then same = m.behind.event.startSec = program.startSec
    target = limit - 5
    if same
        ' The estimate was off: step back, and in the end play from the start.
        m.behind.attempts = m.behind.attempts + 1
        if m.behind.attempts >= 3 then target = program.inS else target = m.previewOpenAt - 60
    end if
    if target < program.inS then target = program.inS
    if target >= m.previewOpenAt and m.previewOpenAt > program.inS then target = program.inS
    print "Roku limit on "; program.title; ": opened at "; m.previewOpenAt; ", limit "; limit; ", reopening at "; target
    b = m.behind
    if not same then b = {policy: "switch", offered: false, attempts: 0, reason: "limit"}
    b.event = program
    b.limit = limit
    b.lastPos = target
    b.cardStartSec = 0
    b.waiting = false
    openStream(program, m.previewKey, target)
    m.behind = b
    if m.fullscreen and not b.offered then openSyncPanel(true)
    return true
end function

' Reopens whatever was playing, live or behind, after an error or a stall.
sub retryStream(channel as Object)
    if m.behind = invalid
        startPreview(channel)
        return
    end if
    event = m.behind.event
    if event.kind = "card" then return
    target = m.behind.lastPos
    if target < event.inS then target = event.inS
    if m.behind.limit > 0 and target > m.behind.limit then target = m.behind.limit - 5
    b = m.behind
    openStream(event, channel.id + "@" + event.startSec.ToStr(), target)
    m.behind = b
end sub

' Plays one event of the lineup while behind: a program or commercial from a
' position, or a station-break card timed by the clock.
sub playBehindEvent(event as Object, startAt as Integer)
    b = m.behind
    channel = m.channels[m.currentIndex]
    key = channel.id + "@" + event.startSec.ToStr()
    b.event = event
    b.waiting = false
    b.limit = -1
    b.attempts = 0
    b.lastPos = startAt
    if event.kind = "card"
        stopPreview()
        m.previewKey = key
        hideStatic()
        b.cardStartSec = currentEpochSeconds()
        m.breakText.Text = ""
        m.breakCard.Visible = true
    else
        openStream(event, key, startAt)
    end if
    m.behind = b
    showPlaybackBanner()
end sub

function nextEventAfter(channel as Object, event as Object) as Dynamic
    endSec = event.startSec + event.duration
    for each candidate in channel.timeline
        if candidate.startSec >= endSec - 2
            ' A gap means the listings do not reach back that far yet.
            if candidate.startSec > endSec + 60 then return invalid
            return candidate
        end if
    end for
    return invalid
end function

' The behind program is over (file finished, slot length reached or card done).
sub behindProgramEnded()
    if m.behind = invalid then return
    if m.behind.policy = "finish"
        goLive()
    else if m.behind.policy = "delayed"
        channel = m.channels[m.currentIndex]
        nextEvent = nextEventAfter(channel, m.behind.event)
        if nextEvent = invalid
            m.behind.waiting = true
            m.behind.waitSince = currentEpochSeconds()
            showStatic()
            requestSchedules()
        else
            playBehindEvent(nextEvent, nextEvent.inS)
        end if
    end if
end sub

sub behindTick(nowSec as Integer)
    b = m.behind
    event = b.event
    if b.waiting
        channel = m.channels[m.currentIndex]
        nextEvent = nextEventAfter(channel, event)
        if nextEvent <> invalid
            playBehindEvent(nextEvent, nextEvent.inS)
        else if nowSec - b.waitSince >= 15
            b.waitSince = nowSec
            requestSchedules()
        end if
        return
    end if
    if event.kind = "card"
        elapsedMs = (nowSec - b.cardStartSec) * 1000
        text = ""
        for each slide in event.slides
            if slide.at <= elapsedMs then text = slide.text
        end for
        if m.breakText.Text <> text then m.breakText.Text = text
        if nowSec - b.cardStartSec >= event.duration then behindProgramEnded()
    else if m.previewHasStream and not m.userPaused
        position = m.previewVideo.position
        if position > 0 then b.lastPos = Int(position)
        if b.policy <> "switch" and position >= event.inS + event.duration - 0.5 then behindProgramEnded()
    end if
    ' More than a day behind is past what the listings can rebuild.
    if m.behind <> invalid
        if behindDelaySec() > 86400 then goLive()
    end if
end sub

sub goLive()
    m.userPaused = false
    stopPreview()
    channel = m.channels[m.currentIndex]
    startPreview(channel)
    if m.fullscreen
        layoutBreakCard()
        showPlaybackBanner()
    end if
end sub

' Plays the program on screen from its beginning. From live this goes behind,
' finishing the program and then rejoining live, unless the viewer picks more.
sub restartProgram()
    channel = m.channels[m.currentIndex]
    program = playingProgram(channel)
    if program = invalid then return
    if program.kind = "card" then return
    if m.behind = invalid then m.behind = {policy: "finish", offered: true, attempts: 0, reason: "restart", limit: -1, lastPos: 0, cardStartSec: 0, waiting: false, event: program}
    m.userPaused = false
    playBehindEvent(program, program.inS)
end sub

' ---- Playback options panel (* in full screen) -------------------------------

sub openSyncPanel(automatic as Boolean)
    if not m.fullscreen then return
    channel = m.channels[m.currentIndex]
    items = [{text: "Keep watching", action: "close"}]
    program = playingProgram(channel)
    if program <> invalid
        if program.kind <> "card" then items.Push({text: "Start this program from the beginning", action: "restart"})
    end if
    if m.behind <> invalid
        items.Push({text: "Back to live", action: "live"})
        policies = [
            {id: "switch", text: "At the next live program, switch to it (back in sync)"},
            {id: "finish", text: "Finish this program, then rejoin live"},
            {id: "delayed", text: "Stay delayed: keep playing the channel in order"}
        ]
        for each policy in policies
            mark = "[   ]  "
            if m.behind.policy = policy.id then mark = "[ • ]  "
            items.Push({text: mark + policy.text, action: "policy:" + policy.id})
        end for
        m.syncTitle.Text = "OUT OF SYNC  ·  " + spelunkrDuration(behindDelaySec()) + " BEHIND SPELUNKR.TV"
        if m.behind.reason = "limit" and m.behind.limit > 0
            m.syncSubtitle.Text = "Roku's player can't join this tape live past " + spelunkrDuration(m.behind.limit - m.behind.event.inS) + ", so it is playing from as far as it can reach."
        else
            m.syncSubtitle.Text = "You are watching behind the website's schedule. Pick what happens next."
        end if
        m.behind.offered = true
    else
        m.syncTitle.Text = "PLAYBACK OPTIONS"
        m.syncSubtitle.Text = "Watching live, in sync with spelunkr.tv."
    end if
    if program <> invalid
        if program.subs <> invalid
            state = "Off"
            if m.subtitlesOn then state = "On"
            kind = "English"
            if program.subs.source = "machine" then kind = "English, machine-translated"
            items.Push({text: "Subtitles: " + state + "  (" + kind + ")", action: "subs"})
        end if
    end if
    items.Push({text: "Back to the guide", action: "guide"})
    m.panelItems = items
    m.panelIndex = 0
    m.panelOpen = true
    renderSyncPanel()
    m.playerBanner.Visible = false
    m.syncPanel.Visible = true
    m.panelTimer.Control = "stop"
    if automatic then m.panelTimer.Control = "start"
end sub

sub renderSyncPanel()
    for slot = 0 to m.syncItemLabels.Count() - 1
        label = m.syncItemLabels[slot]
        if slot < m.panelItems.Count()
            label.Text = m.panelItems[slot].text
            label.Visible = true
        else
            label.Visible = false
        end if
    end for
    m.syncHighlight.Translation = [14, 114 + m.panelIndex * 36]
end sub

sub closeSyncPanel()
    if not m.panelOpen then return
    m.panelOpen = false
    m.syncPanel.Visible = false
    m.panelTimer.Control = "stop"
end sub

function onSyncPanelKey(key as String) as Boolean
    ' Any button means the viewer is choosing: no more automatic close.
    m.panelTimer.Control = "stop"
    if key = "up"
        if m.panelIndex > 0 then m.panelIndex = m.panelIndex - 1
        renderSyncPanel()
    else if key = "down"
        if m.panelIndex < m.panelItems.Count() - 1 then m.panelIndex = m.panelIndex + 1
        renderSyncPanel()
    else if key = "OK"
        applySyncAction(m.panelItems[m.panelIndex].action)
    else if key = "back"
        closeSyncPanel()
        showPlaybackBanner()
    else if key = "play"
        togglePause()
    else if key = "options"
        return false
    end if
    return true
end function

sub applySyncAction(action as String)
    closeSyncPanel()
    if action = "subs"
        m.subtitlesOn = not m.subtitlesOn
        if m.subtitlesOn then saveSetting("subtitles", "on") else saveSetting("subtitles", "off")
        updateSubtitleTimer()
    else if action = "restart"
        restartProgram()
    else if action = "live"
        goLive()
    else if action = "guide"
        exitFullscreen()
        return
    else if Left(action, 7) = "policy:"
        if m.behind <> invalid
            m.behind.policy = Mid(action, 8)
            if m.behind.policy = "switch"
                ' The live program already moved on: switching means now.
                channel = m.channels[m.currentIndex]
                refreshChannelSchedule(channel)
                if channel.now <> invalid
                    if channel.now.startSec <> m.behind.event.startSec then goLive()
                end if
            end if
        end if
    end if
    showPlaybackBanner()
end sub

' Fills the fullscreen banner from the player's real position. Called once a
' second while it shows; it never changes whether the banner is visible.
sub renderPlaybackBanner()
    channel = m.channels[m.currentIndex]
    m.playerChannel.Text = "CH " + channel.dial + "  ·  " + channel.name
    if m.playerLogo.Uri <> channel.logoUri then m.playerLogo.Uri = channel.logoUri
    program = playingProgram(channel)
    if m.behind <> invalid then m.playerChannel.Text = m.playerChannel.Text + "  ·  " + behindLabel()
    if program <> invalid
        if program.subs <> invalid then m.playerChannel.Text = m.playerChannel.Text + "  ·  CC"
    end if
    ' Now & next: what follows on the live schedule, and when.
    nextText = ""
    if m.behind = invalid and channel.next <> invalid then nextText = "NEXT  " + channel.next.title + "  ·  " + localTimeLabel(channel.next.startSec)
    if m.playerNext.Text <> nextText then m.playerNext.Text = nextText
    position = 0
    duration = 0
    if program <> invalid
        m.playerTitle.Text = program.title
        duration = program.duration
        if program.kind = "card" and m.behind <> invalid
            position = currentEpochSeconds() - m.behind.cardStartSec
        else if program.kind = "card"
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
    ' Any stop ends out-of-sync playback; the code that resumes it sets it again.
    m.behind = invalid
    m.activeSubs = invalid
    m.activeCues = invalid
    updateSubtitleTimer()
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
    ' Out of sync and told to keep going: the live schedule moving on does not
    ' cut the program short (behindProgramEnded decides what plays next).
    if m.behind <> invalid
        if m.behind.policy <> "switch" then return
    end if
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
    ' Ask for where the broadcast will be once this file's index has loaded.
    startAt = channel.elapsed + predictOpenSeconds(moov)
    if startAt >= program.duration - 2 then startAt = channel.elapsed
    openStream(program, key, startAt + program.inS)
end sub

' Opens one program's file at a position in the file (seconds, inS included).
sub openStream(program as Object, key as String, startAt as Integer)
    moov = 0
    if program.moov <> invalid then moov = program.moov
    content = CreateObject("roSGNode", "ContentNode")
    content.Url = streamUrl(program.url)
    content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    content.Title = program.title
    content.StreamFormat = LCase(program.streamFormat)
    content.ContentType = "movie"
    content.Length = program.inS + program.duration
    if startAt > 1 then content.PlayStart = startAt
    showStatic()
    m.breakCard.Visible = false
    m.previewKey = key
    m.previewProgram = program
    m.previewOpenAt = startAt
    m.previewHasStream = true
    m.previewStartedAt = currentEpochSeconds()
    m.lastBufferPct = -1
    m.lastBufferMoveSec = m.previewStartedAt
    m.openTimer.Mark()
    m.openMoov = moov
    m.lastVideoPosition = -1.0
    m.previewSeekFixes = 0
    m.userSeeked = false
    m.previewVideo.Content = content
    m.previewVideo.Control = "play"
    m.previewVideo.Visible = true
    hideVideoHud(m.previewVideo)
    setSubtitleSource(program)
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
    updateSubtitleTimer()
    ' Fell back in the preview: offer the choices once now that the viewer is here.
    if m.behind <> invalid
        if not m.behind.offered then openSyncPanel(true)
    end if
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
    ' Out of sync, a pause just adds to the delay, like a DVR.
    if m.behind <> invalid
        if m.previewHasStream then m.previewVideo.control = "resume"
        return
    end if
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
    closeSyncPanel()
    ' The guide shows the live schedule, so a delay the viewer chose ends here.
    ' The automatic fallback stays: live would only fail again on that tape.
    chosenDelay = false
    if m.behind <> invalid then chosenDelay = m.behind.policy <> "switch"
    if chosenDelay
        stopPreview()
        m.fullscreen = false
        startPreview(m.channels[m.currentIndex])
    end if
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
    updateSubtitleTimer()
    m.top.SetFocus(true)
end sub

sub hideGuideChrome(hide as Boolean)
    m.guideBack.Visible = not hide
    m.guideFront.Visible = not hide
    ' The static stays: in full screen it covers the screen until the picture is up.
    if hide then m.previewBadge.Visible = false
end sub

sub moveSelection(delta as Integer)
    ' The lineup wraps round: past the last channel comes the first again.
    count = m.channels.Count()
    if count = 0 then return
    targetIndex = ((m.currentIndex + delta) mod count + count) mod count
    if targetIndex = m.currentIndex then return
    m.pendingTuneId = ""
    ' Moving off the bottom or top row scrolls the list by one; a page moves it by eight.
    slot = slotOfChannel(targetIndex)
    if delta = 8 or delta = -8
        m.rowTop = ((m.rowTop + delta) mod count + count) mod count
        renderGuideRows()
    else if slot < 0 or slot > 7
        if delta > 0 then shiftRows(1) else shiftRows(-1)
    end if
    showChannel(targetIndex, true)
    ' Looking ahead in time: scrolling channels keeps the time view a while longer.
    if m.browseOffsetSec <> 0
        showBrowseStatus()
        m.browseTimer.Control = "stop"
        m.browseTimer.Control = "start"
    end if
end sub

' Channel up/down while watching full screen, like a TV: Up goes to the next
' higher dial, wrapping at either end. The new stream opens only once flipping
' settles (previewTimer), with static and the banner showing meanwhile.
sub fullscreenChannelStep(delta as Integer)
    count = m.channels.Count()
    if count < 2 then return
    closeSyncPanel()
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
    if m.panelOpen then return onSyncPanelKey(key)
    if m.fullscreen
        ' On Roku TVs, * during full-screen video opens the TV's own picture
        ' settings, which the app cannot block, so the app's options use OK.
        if key = "OK"
            openSyncPanel(false)
        else if key = "back"
            exitFullscreen()
        else if key = "options"
            ' Leave * to the Roku TV menu.
            return false
        else if key = "left" or key = "right"
            program = playingProgram(m.channels[m.currentIndex])
            canSeek = false
            if program <> invalid then canSeek = program.kind <> "card" and m.previewHasStream
            if canSeek
                target = m.previewVideo.position
                if key = "left" then target = target - 10 else target = target + 10
                if target < program.inS then target = program.inS
                if target > program.inS + program.duration then target = program.inS + program.duration
                ' Past a tape's Roku limit a jump fails, so stop just short of it.
                if m.behind <> invalid
                    if m.behind.limit > 0 and target > m.behind.limit then target = m.behind.limit
                end if
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
    if m.scanOn = true and m.active
        if key = "up" or key = "down"
            if key = "down" then scanManualStep(1) else scanManualStep(-1)
            return true
        else if key = "play" or key = "back"
            ' Play turns Scan on and off; Back also ends it.
            exitScan()
            return true
        else if key = "left" or key = "right"
            ' A page is eight channels, as in the guide.
            if key = "right" then scanManualStep(8) else scanManualStep(-8)
            return true
        end if
    end if
    if key = "play" and m.active
        enterScan()
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
    else if key = "fastforward" and m.active
        browseTime(1800)
        return true
    else if key = "rewind" and m.active
        browseTime(-1800)
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
        description = dirLabel(card, 16, 66, 568, 112, "font:SmallSystemFont", "0xE8EAF0FF")
        description.Wrap = true
        description.MaxLines = 3
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
                fitDirectoryDescription(view.description, channel.description)
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

' A card's description keeps the normal size when it fits in three lines and
' steps down only as far as it must, so the whole text shows without "...".
sub fitDirectoryDescription(label as Object, text as String)
    fitLabel(label, text, "font:SmallSystemFont", [22, 20, 19, 18, 17, 16], 568, 112)
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
        if view.nowTitle.Text <> title then fitLabel(view.nowTitle, title, "font:SmallSystemFont", [22, 20, 19, 18], 568, 22)
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
    ' The now line and the listings creep left with the clock (whole pixels).
    if m.stripGlide.State <> "running" then updateTimeStrip(nowSec, false)
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
        ' Scan is chosen playback, so it keeps going far longer; after 4 hours
        ' without a button it stops so a forgotten TV does not stream all night.
        if m.scanOn = true
            if nowSec - m.lastInputSec >= 14400
                exitScan()
                pauseIdlePreview()
            end if
        else if nowSec - m.lastInputSec >= m.idleSeconds
            pauseIdlePreview()
        end if
    end if
    channel = m.channels[m.currentIndex]
    refreshChannelSchedule(channel)
    if airingKey(channel) <> m.infoAiringKey
        updateProgramInfo(channel)
        currentSlot = slotOfChannel(m.currentIndex)
        if currentSlot >= 0 then renderRowCells(currentSlot, channel)
        if not m.previewPending then startPreview(channel)
        showPlaybackBanner()
    else if m.fullscreen
        if m.playerBanner.Visible then renderPlaybackBanner()
    else
        updateProgress(channel)
    end if
    if m.behind <> invalid then behindTick(nowSec) else updateBreakCard(channel)
    if m.previewHasStream then hideVideoHud(m.previewVideo)
    if m.previewRetryAt > 0 and nowSec >= m.previewRetryAt and not m.previewPending
        m.previewRetryAt = 0
        retryStream(channel)
    end if
    if m.previewHasStream and not m.previewPending and m.previewStartedAt > 0
        ' Loading a big index (12-38 MB on some TOONERTIA tapes) shows as a
        ' rising buffer percentage; only a stream that stops moving is stuck.
        status = m.previewVideo.bufferingStatus
        if type(status) = "roAssociativeArray"
            if status.percentage <> invalid
                if status.percentage <> m.lastBufferPct
                    m.lastBufferPct = status.percentage
                    m.lastBufferMoveSec = nowSec
                end if
            end if
        end if
    end if
    if m.previewHasStream and not m.previewPending
        stuck = false
        if m.previewStartedAt > 0
            openFor = nowSec - m.previewStartedAt
            ' Allow the expected open time for this index, plus a margin.
            allowed = 45 + predictOpenSeconds(m.openMoov)
            if openFor >= allowed and nowSec - m.lastBufferMoveSec >= 20 then stuck = true
            if openFor >= 180 then stuck = true
        end if
        if stuck
            print "Stream stuck opening after "; nowSec - m.previewStartedAt; " s, reopening"
            ' A stream stuck opening never reports an error, so give it a fresh start.
            if m.previewRetries < 2
                m.previewRetries = m.previewRetries + 1
                m.previewKey = ""
                retryStream(channel)
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
        ' The strip starts an hour before the current hour; a new hour moves it on.
        rebaseTimeStrip()
        updateTimeStrip(nowSec, false)
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
    for slot = 0 to m.rowChannel.Count() - 1
        channelIndex = m.rowChannel[slot]
        if channelIndex < 0 then continue for
        channel = m.channels[channelIndex]
        refreshChannelSchedule(channel)
        nowStart = -1
        if channel.now <> invalid then nowStart = channel.now.startSec
        if nowStart <> m.rowViews[slot].highlightStart then renderRowCells(slot, channel)
    end for
end sub

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
