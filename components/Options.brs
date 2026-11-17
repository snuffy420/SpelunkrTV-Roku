' ---- Options, schedules, reminders and the quick channel switch ---------------
' The options sheet opens with Replay in the guide. The same sheet shows the
' About page, the theme list, the reminders list and a channel's next 24 hours
' (SCHEDULE on a directory card). Reminders work like the website's REMIND ME,
' without Discord: while the app is open, a card pops up 15 minutes before the
' program starts. Replay in full screen opens the quick channel list instead.

sub initOptions()
    m.sheet = m.top.FindNode("sheet")
    m.sheetTitle = m.top.FindNode("sheetTitle")
    m.sheetSubtitle = m.top.FindNode("sheetSubtitle")
    m.sheetHighlight = m.top.FindNode("sheetHighlight")
    m.sheetBody = m.top.FindNode("sheetBody")
    m.sheetPage = m.top.FindNode("sheetPage")
    m.sheetMode = ""
    m.sheetItems = []
    m.sheetIndex = 0
    m.sheetTop = 0
    m.sheetRowViews = []
    rows = m.top.FindNode("sheetRows")
    for slot = 0 to 11
        y = slot * 36
        left = addSheetLabel(rows, 0, y, 170, "font:SmallBoldSystemFont", "0x00CCDDEE")
        text = addSheetLabel(rows, 0, y, 884, "font:SmallBoldSystemFont", "0xE8EAF0FF")
        right = addSheetLabel(rows, 584, y, 300, "font:SmallestBoldSystemFont", "0xFFD740FF")
        right.HorizAlign = "right"
        m.sheetRowViews.Push({left: left, text: text, right: right})
    end for
    buildHintRow("sheetHints", [{icons: ["dpad-updown"], text: "CHOOSE"}, {icons: ["ok"], text: "SELECT"}, {icons: ["back"], text: "BACK"}])
    buildScheduleViews()

    m.quickPanel = m.top.FindNode("quickPanel")
    m.quickHighlight = m.top.FindNode("quickHighlight")
    m.quickOpen = false
    m.quickIndex = 0
    m.quickTop = 0
    m.quickViews = []
    quickRows = m.top.FindNode("quickRows")
    dialFont = CreateObject("roSGNode", "Font")
    dialFont.Uri = "font:MediumBoldSystemFont"
    dialFont.Size = 30
    for slot = 0 to 8
        group = quickRows.CreateChild("Group")
        group.Translation = [0, slot * 64]
        dial = addSheetLabel(group, 14, 4, 64, "", "0xFFE22EFF")
        dial.Font = dialFont
        dial.Height = 54
        dial.HorizAlign = "center"
        logo = group.CreateChild("Poster")
        logo.Translation = [84, 13]
        logo.Width = 34
        logo.Height = 34
        logo.LoadDisplayMode = "scaleToFit"
        name = addSheetLabel(group, 130, 3, 264, "font:SmallBoldSystemFont", "0xFFE22EFF")
        name.Height = 28
        playing = addSheetLabel(group, 130, 29, 264, "font:SmallestSystemFont", "0xC7D2F2FF")
        playing.Height = 34
        star = addFavoriteStar(group, 108, 8, 16)
        m.quickViews.Push({group: group, dial: dial, logo: logo, star: star, name: name, playing: playing})
    end for
    buildHintRow("quickHints", [{icons: ["dpad-updown"], text: "SCROLL"}, {icons: ["dpad-leftright"], text: "FAVORITES"}, {icons: ["ok"], text: "WATCH"}, {icons: ["back"], text: "CLOSE"}], true)
    m.quickTitle = m.top.FindNode("quickTitle")
    m.quickTimer = makeTimer(20, false, "closeQuick")

    m.alertPanel = m.top.FindNode("alertPanel")
    m.alertOpen = false
    m.alertItem = invalid
    buildHintRow("alertHints", [{icons: ["ok"], text: "TUNE IN"}, {icons: ["back"], text: "DISMISS"}])
    m.alertTimer = makeTimer(90, false, "closeAlert")
    loadReminders()
    m.lastReminderCheck = 0
end sub

function addSheetLabel(parent as Object, x as Integer, y as Integer, w as Integer, fontName as String, color as String) as Object
    label = parent.CreateChild("Label")
    label.Translation = [x, y]
    label.Width = w
    label.Height = 36
    label.VertAlign = "center"
    if fontName <> "" then label.Font = fontName
    sc(label, "Color", color)
    return label
end function

' ---- The sheet ------------------------------------------------------------------

sub openSheet(mode as String, title as String, subtitle as String, items as Object, index as Integer)
    if mode = "options" and m.scanOn = true then exitScan()
    m.sheetMode = mode
    ' Options and Theme are short lists: a compact box. The rest need the room.
    if mode = "options" or mode = "theme"
        rows = items.Count()
        if rows > 12 then rows = 12
        layoutSheet(680, 106 + rows * 36 + 64)
    else
        layoutSheet(940, 600)
    end if
    m.sheetTitle.Text = title
    m.sheetSubtitle.Text = subtitle
    m.sheetItems = items
    if index >= items.Count() then index = 0
    m.sheetIndex = index
    m.sheetTop = 0
    m.sheetBody.Visible = false
    m.schedList.Visible = false
    m.sheet.Visible = true
    renderSheet()
end sub

' Sizes the sheet and centres it; rows, labels and hints follow its width.
sub layoutSheet(w as Integer, h as Integer)
    m.sheetW = w
    m.sheet.Translation = [Int((1280 - w) / 2), Int((720 - h) / 2)]
    m.top.FindNode("sheetBack").Width = w
    m.top.FindNode("sheetBack").Height = h
    m.top.FindNode("sheetRule").Width = w
    m.sheetTitle.Width = w - 56
    m.sheetSubtitle.Width = w - 56
    m.sheetBody.Width = w - 56
    m.sheetHighlight.Width = w - 28
    m.sheetPage.Translation = [w - 300, h - 42]
    m.top.FindNode("sheetHints").Translation = [28, h - 42]
    for each view in m.sheetRowViews
        view.right.Translation = [w - 356, view.right.Translation[1]]
    end for
end sub

sub renderSheet()
    count = m.sheetItems.Count()
    if m.sheetIndex < m.sheetTop then m.sheetTop = m.sheetIndex
    if m.sheetIndex > m.sheetTop + 11 then m.sheetTop = m.sheetIndex - 11
    timed = m.sheetMode = "schedule" or m.sheetMode = "reminders"
    for slot = 0 to 11
        view = m.sheetRowViews[slot]
        index = m.sheetTop + slot
        if index < count and not m.sheetBody.Visible
            item = m.sheetItems[index]
            view.left.Text = textOf(item.left)
            view.left.Visible = timed
            if timed
                view.text.Translation = [180, slot * 36]
                view.text.Width = m.sheetW - 56 - 180 - 210
            else
                view.text.Translation = [0, slot * 36]
                view.text.Width = m.sheetW - 56 - 200
            end if
            if timed
                ' Long program titles step down a size or two rather than trail off.
                fitLabel(view.text, textOf(item.text), "font:SmallBoldSystemFont", [22, 20, 18, 17, 16], view.text.Width, 36)
            else
                ' Room for the right-hand tag (CURRENT, NONE SET...), then shrink to fit.
                width = m.sheetW - 56
                if textOf(item.right) <> "" then width = width - 180
                view.text.Width = width
                fitLabel(view.text, textOf(item.text), "font:SmallBoldSystemFont", [22, 20, 18, 17, 16], width - 12, 36)
            end if
            view.right.Text = textOf(item.right)
            if item.dim = true then sc(view.text, "Color", "0x99A3CCFF") else sc(view.text, "Color", "0xE8EAF0FF")
            view.text.Visible = true
            view.right.Visible = true
        else
            view.left.Visible = false
            view.text.Visible = false
            view.right.Visible = false
        end if
    end for
    m.sheetHighlight.Visible = count > 0 and not m.sheetBody.Visible
    m.sheetHighlight.Translation = [14, 106 + (m.sheetIndex - m.sheetTop) * 36]
    if count > 12 and not m.sheetBody.Visible
        m.sheetPage.Text = (m.sheetIndex + 1).ToStr() + " OF " + count.ToStr()
    else
        m.sheetPage.Text = ""
    end if
end sub

function textOf(value as Dynamic) as String
    if value = invalid then return ""
    return value
end function

sub closeSheet()
    m.sheetMode = ""
    m.sheet.Visible = false
end sub

function onSheetKey(key as String) as Boolean
    if m.sheetMode = "schedule" then return onScheduleKey(key)
    if m.sheetMode = "about" or m.sheetMode = "whatsnew"
        ' The About and What's new pages turn with the arrows (and OK); Back returns to Options.
        if key = "down" or key = "right" or key = "fastforward" or key = "OK"
            if m.aboutPage < m.aboutPages.Count() - 1 then showAboutPage(m.aboutPage + 1) else if key = "OK" then sheetBack()
        else if key = "up" or key = "left" or key = "rewind"
            if m.aboutPage > 0 then showAboutPage(m.aboutPage - 1)
        else if key = "back" or key = "replay"
            sheetBack()
        end if
        return true
    end if
    if key = "up"
        if m.sheetIndex > 0 then m.sheetIndex = m.sheetIndex - 1
        renderSheet()
    else if key = "down"
        if m.sheetIndex < m.sheetItems.Count() - 1 then m.sheetIndex = m.sheetIndex + 1
        renderSheet()
    else if key = "rewind" or key = "fastforward"
        step12 = 12
        if key = "rewind" then step12 = -12
        m.sheetIndex = m.sheetIndex + step12
        if m.sheetIndex < 0 then m.sheetIndex = 0
        if m.sheetIndex > m.sheetItems.Count() - 1 then m.sheetIndex = m.sheetItems.Count() - 1
        if m.sheetIndex < 0 then m.sheetIndex = 0
        renderSheet()
    else if key = "OK"
        if m.sheetIndex < m.sheetItems.Count() then sheetAction(m.sheetItems[m.sheetIndex])
    else if key = "back" or key = "replay"
        sheetBack()
    end if
    return true
end function

sub sheetBack()
    mode = m.sheetMode
    if mode = "about" or mode = "whatsnew" or mode = "theme" or mode = "reminders"
        openOptions()
    else
        closeSheet()
    end if
end sub

sub sheetAction(item as Object)
    action = textOf(item.action)
    if action = "theme"
        openThemeSheet()
    else if action = "reminders"
        openRemindersSheet()
    else if action = "clearReminders"
        count = m.reminders.Count()
        m.reminders = []
        saveReminders()
        openOptions()
        if count = 1 then m.sheetSubtitle.Text = "1 reminder removed." else m.sheetSubtitle.Text = count.ToStr() + " reminders removed."
    else if action = "about"
        openAbout()
    else if action = "whatsnew"
        openPages("whatsnew", "WHAT'S NEW", whatsNewPages())
    else if action = "close"
        closeSheet()
    else if action = "zip"
        openZipPad()
    else if action = "fav" or Left(action, 4) = "set:"
        if action = "fav" then toggleFavorite(m.channels[m.currentIndex]) else cycleSetting(Mid(action, 5))
        index = m.sheetIndex
        top = m.sheetTop
        openOptions()
        m.sheetIndex = index
        m.sheetTop = top
        renderSheet()
    else if Left(action, 6) = "theme:"
        id = Mid(action, 7)
        saveSetting("theme", id)
        applyTheme(id)
        index = m.sheetIndex
        openThemeSheet()
        m.sheetIndex = index
        renderSheet()
    else if Left(action, 7) = "remove:"
        removeReminder(Mid(action, 8))
        index = m.sheetIndex
        openRemindersSheet()
        if index >= m.sheetItems.Count() then index = m.sheetItems.Count() - 1
        if index < 0 then index = 0
        m.sheetIndex = index
        renderSheet()
    end if
end sub

' ---- Options, About and Theme ---------------------------------------------------

sub openOptions()
    count = m.reminders.Count()
    reminderText = "None set"
    if count = 1 then reminderText = "1 set" else if count > 1 then reminderText = count.ToStr() + " set"
    channel = invalid
    if m.channels.Count() > m.currentIndex then channel = m.channels[m.currentIndex]
    items = [{text: "Theme", right: UCase(themeName(m.themeId)), action: "theme"}]
    if channel <> invalid
        state = "NOT A FAVORITE"
        if isFavorite(channel) then state = "FAVORITE"
        items.Push({text: "Favorite: " + channel.dial + "  " + channel.name, right: state, action: "fav"})
    end if
    zip = weatherZip()
    zipText = "OFF"
    if zip <> "" then zipText = loadSetting("zipCountry", "US") + " " + zip
    items.Push({text: "Weather in the header", right: zipText, action: "zip"})
    for each setting in settingList()
        items.Push({text: setting.label, right: settingText(setting), action: "set:" + setting.id})
    end for
    items.Append([
        {text: "Reminders", right: UCase(reminderText), action: "reminders"},
        {text: "Remove all reminders", action: "clearReminders", dim: count = 0},
        {text: "What's new in this version", action: "whatsnew"},
        {text: "About Spelunkr", action: "about"},
        {text: "Close", action: "close"}
    ])
    version = CreateObject("roAppInfo").GetVersion()
    openSheet("options", "OPTIONS", "Spelunkr TV Guide (Unofficial)  ·  v" + version, items, 0)
end sub

sub openThemeSheet()
    items = []
    selected = 0
    for each theme in themeList()
        mark = ""
        if theme.id = m.themeId
            mark = "CURRENT"
            selected = items.Count()
        end if
        items.Push({text: theme.name + "  ·  " + theme.note, right: mark, action: "theme:" + theme.id})
    end for
    openSheet("theme", "THEME", "How the guide looks. Your choice is remembered.", items, selected)
end sub

sub openAbout()
    openPages("about", "ABOUT SPELUNKR", aboutPages())
end sub

' A few pages of text in the large sheet, turned with the arrows.
sub openPages(mode as String, title as String, pages as Object)
    openSheet(mode, title, "", [], 0)
    m.aboutPages = pages
    m.sheetBody.Visible = true
    renderSheet()
    showAboutPage(0)
end sub

' What changed, for viewers who never see the GitHub page. Newest first.
function whatsNewPages() as Object
    return [
        {heading: "version 1.9.8", lines: [
            "OPTIONS",
            "Press Replay in the guide (the OPTIONS button) for themes, favorites, settings, reminders, this list and About Spelunkr.",
            "",
            "THEMES",
            "Pick how the guide looks: Classic, Glass (frosted 3D panels in Spelunkr's colours), Neon (glowing outlines), Spelunkr Neon (orange and blue glow) or Channel Color, which fades to each channel's own colour as you move. Your choice is remembered.",
            "",
            "CHANNEL SCHEDULES",
            "Every card in the directory (*) has a SCHEDULE button with the channel's next 24 hours, in your time."]},
        {heading: "version 1.9.8, continued", lines: [
            "REMINDERS",
            "In a schedule, OK on a program sets a reminder. While the app is open, a card pops up 15 minutes before it starts: OK tunes in, Back dismisses. Options lists your reminders and can remove them all.",
            "",
            "QUICK CHANNEL LIST",
            "While watching full screen, press Replay for every channel and what's on it. The picture keeps playing until you pick one with OK; Back closes the list. Up and Down still flip channels as before.",
            "",
            "ALSO NEW",
            "A new splash screen and Roku home-screen icon, and a slimmer row of buttons along the bottom of the guide."]},
        {heading: "version 1.9.8, settings and favorites", lines: [
            "FAVORITES",
            "In Options, mark the channel you're on as a favorite. A gold star shows on its logo, and in the quick channel list Left and Right switch between all channels and your favorites.",
            "",
            "SETTINGS IN OPTIONS",
            "Start on your last channel, your first favorite or the first channel. A 12- or 24-hour clock. The guide preview with sound, muted or off. Scan speed. Subtitles on or off. How long before the screensaver.",
            "",
            "THE PREVIEW AND TUNING",
            "A bigger 4:3 preview, a big channel number while you flip, and a STAND BY card that shows how far a tape has loaded."]},
        {heading: "earlier versions", lines: [
            "1.9.4",
            "New channel: HENSHIN on 301, with Japanese commercials in its breaks. The app is labelled Unofficial on the splash screen, in the guide and on the Roku home screen.",
            "",
            "1.9.3",
            "English subtitles for the tapes Spelunkr subtitles (the Japanese channels and their commercials): turn them on with OK, Subtitles while watching. Schedules update live when Spelunkr changes them, and the full-screen banner shows what's on next."]}
    ]
end function

sub showAboutPage(index as Integer)
    m.aboutPage = index
    page = m.aboutPages[index]
    m.sheetSubtitle.Text = page.heading
    m.sheetBody.Text = page.lines.Join(Chr(10))
    m.sheetPage.Text = "PAGE " + (index + 1).ToStr() + " OF " + m.aboutPages.Count().ToStr()
end sub

' Everything spelunkr.tv/about covers, page by page, in this app's own words.
' The donation and tip buttons stay on the website (store apps can't carry
' them); the last page sends viewers there.
function aboutPages() as Object
    channels = "Its channels"
    if m.channels.Count() > 0 then channels = "All " + m.channels.Count().ToStr() + " of its channels"
    return [
        {heading: "the station", lines: [
            "Spelunkr is a TV guide for a station that never signs off. " + channels + " run around the clock, whether or not anyone is tuned in.",
            "",
            "Expect creature features, old educational reels, crime shows, vintage cartoons and home-taped broadcasts of decades-old Saturday mornings with the original commercials still in them.",
            "",
            "There's no menu of videos to choose from. When you tune in, you join whatever is airing, at the same moment as every other viewer of that channel, just like broadcast TV.",
            "",
            "THE PRICE",
            "Free. Watching needs no account, there are no ads, and nothing is for sale."]},
        {heading: "the tapes and the internet archive", lines: [
            "The recordings aren't Spelunkr's. Each one streams from the Internet Archive, the non-profit library that preserved them. Spelunkr hosts no video: your Roku plays the Archive's file directly. On the website, each title carries a ""via archive.org"" link to the tape's Archive page, which shows who uploaded it.",
            "",
            "That means watching costs the Archive bandwidth, just as it would on archive.org, and the Archive is funded by donations.",
            "",
            "Spelunkr has no affiliation with the Internet Archive and no endorsement from it. The credit belongs to the Archive and to the people who recorded these broadcasts on their VCRs and, years later, uploaded them.",
            "",
            "Spelunkr itself is run by one person and paid for out of pocket. Support is welcome but optional, and it gets you nothing extra: every channel is free for everyone and will stay free."]},
        {heading: "what spelunkr makes, and fixing tapes", lines: [
            "SPELUNKR'S OWN WORK",
            "The guide, the schedules and the brief interludes between programs: short text cards set to music. The music is Creative Commons or public domain and is credited on screen. The programs themselves are other people's work.",
            "",
            "WHEN A TAPE STOPS WORKING",
            "Recordings occasionally vanish from the Archive. Spelunkr checks all of them weekly and fills any missing slot with another tape. To report one that won't play, post in the #bugs channel on Spelunkr's Discord.",
            "",
            "ASKING FOR A TAPE TO BE REMOVED",
            "Uploaders and rights holders can ask the Program Director on Spelunkr's Discord to take a tape off a channel; give the channel and the title. Spelunkr handles its own schedule. Taking the file off the Archive is a separate request to the Archive, which has its own instructions."]},
        {heading: "checking tapes, and data when you watch", lines: [
            "Each tape is spot-checked, by sight and sound, before it joins a channel, to confirm it matches its description. A few frames and notes from that check are kept privately and never shared.",
            "",
            "WATCHING ON THE WEBSITE",
            "No account and no cookies. Your browser stores a few preferences, such as your last channel. Visits are counted with Cloudflare Web Analytics, which is cookie-free. Spelunkr tallies, hourly, how many visits use TUNE IN, WATCH or a channel page, and counts viewers per channel with a random number that disappears when the tab closes. Anonymous reactions are kept without a name. Each tape load is logged without any name or ID (the tape, whether it played, its start-up time and an approximate connection speed) and deleted after 90 days. Your IP address isn't in any of these records. The video comes from archive.org and the fonts from Google, and the site's hosting providers see connections in their server logs, as for any website."]},
        {heading: "signing in on the website", lines: [
            "An account is only needed to comment, and it works through Discord. Signing in adds you to the Spelunkr Discord server; Discord shares your username, avatar and email address. The email is never used or written to, and Spelunkr can't see your messages, friends or other servers.",
            "",
            "Comments appear under your name. Your comments, reactions and per-channel viewing time are stored with your account. New comments are also copied to a private Discord room that only the site's operator sees, so problem comments can be removed fast. Leaving the Discord server doesn't delete your account.",
            "",
            "No data is sold. The services behind the site are Cloudflare (hosting and music), Supabase (database and sign-in) and Discord (sign-in and the private room), and none of it is passed to anyone else. To delete your account and its data, contact the Program Director on the Discord."]},
        {heading: "late-night channels, credits and support", lines: [
            "LATE-NIGHT CHANNELS",
            "Some channels show horror, exploitation films and after-hours public-access TV, unedited. There are no ratings and no age filters.",
            "",
            "CREDITS",
            "Spelunkr is a one-person project. Its bumps, guide text, logos and name are its own. Every video belongs to its creators and streams from the Internet Archive.",
            "",
            "SUPPORTING THE ARCHIVE AND SPELUNKR",
            "For ways to donate to the Internet Archive or tip Spelunkr, visit spelunkr.tv/about.",
            "",
            "This Roku app is an unofficial guide to spelunkr.tv. Spelunkr, its channels and logos belong to Spelunkr; the tapes stream from the Internet Archive."]}
    ]
end function

' ---- Reminders ------------------------------------------------------------------

sub loadReminders()
    m.reminders = []
    stored = ParseJson(loadSetting("reminders", "[]"))
    if type(stored) <> "roArray" then return
    nowSec = currentEpochSeconds()
    for each item in stored
        if type(item) = "roAssociativeArray" and item.startSec <> invalid
            ' Past programs drop off on their own.
            if item.startSec + 1800 > nowSec then m.reminders.Push(item)
        end if
    end for
end sub

sub saveReminders()
    saveSetting("reminders", FormatJson(m.reminders))
end sub

function reminderKey(channelId as String, startSec as Integer) as String
    return channelId + "@" + startSec.ToStr()
end function

function hasReminder(key as String) as Boolean
    for each item in m.reminders
        if item.key = key then return true
    end for
    return false
end function

sub removeReminder(key as String)
    kept = []
    for each item in m.reminders
        if item.key <> key then kept.Push(item)
    end for
    m.reminders = kept
    saveReminders()
end sub

sub openRemindersSheet()
    sorted = []
    for each item in m.reminders
        placed = false
        for i = 0 to sorted.Count() - 1
            if item.startSec < sorted[i].startSec
                sorted.Insert(i, item)
                placed = true
                exit for
            end if
        end for
        if not placed then sorted.Push(item)
    end for
    m.reminders = sorted
    items = []
    for each item in sorted
        items.Push({left: dayTimeLabel(item.startSec), text: item.dial + "  " + item.name + "  ·  " + item.title, right: "OK REMOVES", action: "remove:" + item.key})
    end for
    subtitle = "A reminder pops up 15 minutes before each program, while the app is open. OK removes one."
    if items.Count() = 0
        items.Push({text: "No reminders. Open a channel's SCHEDULE in the directory to set one.", dim: true})
    end if
    openSheet("reminders", "REMINDERS", subtitle, items, 0)
end sub

' "7:30 PM" today, "Tue 7:30 PM" on another day.
function dayTimeLabel(sec as Integer) as String
    day = CreateObject("roDateTime")
    day.FromSeconds(sec)
    day.ToLocalTime()
    today = CreateObject("roDateTime")
    today.ToLocalTime()
    label = localTimeLabel(sec)
    if day.GetDayOfMonth() <> today.GetDayOfMonth() then label = Left(day.GetWeekday(), 3) + " " + label
    return label
end function

' Once every few seconds from onTick: the reminder card 15 minutes ahead.
sub checkReminders(nowSec as Integer)
    if nowSec - m.lastReminderCheck < 5 then return
    m.lastReminderCheck = nowSec
    if m.alertOpen or m.reminders.Count() = 0 then return
    changed = false
    due = invalid
    kept = []
    for each item in m.reminders
        if item.startSec + 600 < nowSec
            changed = true
        else
            kept.Push(item)
            if due = invalid and item.alerted <> true and nowSec >= item.startSec - 900 then due = item
        end if
    end for
    m.reminders = kept
    if due <> invalid
        due.alerted = true
        changed = true
        showAlert(due)
    end if
    if changed then saveReminders()
end sub

sub showAlert(item as Object)
    m.alertItem = item
    minutes = Int((item.startSec - currentEpochSeconds() + 59) / 60)
    head = "REMINDER  ·  STARTS AT " + localTimeLabel(item.startSec)
    if minutes > 1 then head = head + "  ·  IN " + minutes.ToStr() + " MIN" else if minutes <= 0 then head = "REMINDER  ·  ON NOW"
    m.top.FindNode("alertHead").Text = head
    fitLabel(m.top.FindNode("alertChannel"), item.dial + "  " + item.name, "font:SmallBoldSystemFont", [22, 20, 18, 16], 448, 26)
    fitLabel(m.top.FindNode("alertTitle"), item.title, "font:SmallSystemFont", [22, 20, 18, 16, 14], 496, 56)
    logo = m.top.FindNode("alertLogo")
    logo.Uri = "pkg:/images/logos/" + item.id + ".png"
    m.alertOpen = true
    m.alertPanel.Visible = true
    m.alertTimer.Control = "stop"
    m.alertTimer.Control = "start"
end sub

sub closeAlert()
    m.alertOpen = false
    m.alertPanel.Visible = false
    m.alertTimer.Control = "stop"
end sub

' OK tunes in, Back dismisses; every other key works as usual underneath.
function onAlertKey(key as String) as Boolean
    if key = "back"
        closeAlert()
        return true
    else if key = "OK"
        item = m.alertItem
        closeAlert()
        if item <> invalid and m.channelIndexById.DoesExist(item.id) then tuneToChannel(m.channelIndexById[item.id])
        return true
    end if
    return false
end function

' Goes to a channel full screen from wherever the viewer is.
sub tuneToChannel(index as Integer)
    if m.sheetMode <> "" then closeSheet()
    if m.quickOpen then closeQuick()
    if m.panelOpen then closeSyncPanel()
    if m.directoryOpen then closeDirectory()
    if m.scanOn = true then exitScan()
    if m.fullscreen
        if index <> m.currentIndex then fullscreenTune(index)
        return
    end if
    if not m.active then return
    showChannel(index, true)
    requestSchedules()
    tuneInFullscreen(index)
end sub

' ---- A channel's next 24 hours (SCHEDULE in the directory) ----------------------
' Laid out like spelunkr.tv/<channel>/schedule: a yellow band for each part of
' the day, then each program with its time and a REMIND ME button on the left,
' title and description on the right. The focused button glows.

sub buildScheduleViews()
    m.schedList = m.top.FindNode("schedList")
    m.schedViews = []
    for slot = 0 to 7
        group = m.schedList.CreateChild("Group")
        band = group.CreateChild("Group")
        bandBack = band.CreateChild("Rectangle")
        bandBack.Translation = [20, 0]
        bandBack.Width = 900
        bandBack.Height = 30
        sc(bandBack, "Color", "0xFFE22EFF")
        bandText = addSheetLabel(band, 34, 0, 700, "font:SmallBoldSystemFont", "0x14153AFF")
        bandText.Height = 30

        row = group.CreateChild("Group")
        back = row.CreateChild("Rectangle")
        back.Translation = [20, 0]
        back.Width = 900
        back.Height = 96
        stripe = row.CreateChild("Rectangle")
        stripe.Translation = [20, 0]
        stripe.Width = 8
        stripe.Height = 96
        sc(stripe, "Color", "0xD2640FFF")
        clock = addSheetLabel(row, 40, 6, 180, "font:MediumBoldSystemFont", "0xFFE22EFF")
        clock.Height = 32
        glow = row.CreateChild("Rectangle")
        glow.Translation = [33, 41]
        glow.Width = 186
        glow.Height = 46
        sc(glow, "Color", "0xFFD74055")
        outline = row.CreateChild("Rectangle")
        outline.Translation = [38, 46]
        outline.Width = 176
        outline.Height = 36
        faceTop = row.CreateChild("Rectangle")
        faceTop.Translation = [40, 48]
        faceTop.Width = 172
        faceTop.Height = 16
        faceBottom = row.CreateChild("Rectangle")
        faceBottom.Translation = [40, 64]
        faceBottom.Width = 172
        faceBottom.Height = 16
        buttonText = addSheetLabel(row, 38, 46, 176, "font:SmallestBoldSystemFont", "0xFFFFFFFF")
        buttonText.HorizAlign = "center"
        title = addSheetLabel(row, 236, 4, 560, "font:SmallBoldSystemFont", "0xFFFFFFFF")
        title.Height = 32
        length = addSheetLabel(row, 800, 4, 108, "font:SmallestBoldSystemFont", "0x00CCDDEE")
        length.HorizAlign = "right"
        length.Height = 32
        about = addSheetLabel(row, 236, 36, 672, "font:SmallestSystemFont", "0xC7D2F2FF")
        about.Wrap = true
        m.schedViews.Push({group: group, band: band, bandText: bandText, row: row, back: back, stripe: stripe, clock: clock, glow: glow, outline: outline, faceTop: faceTop, faceBottom: faceBottom, buttonText: buttonText, title: title, length: length, about: about})
    end for
end sub

sub openSchedule(channelIndex as Integer)
    channel = m.channels[channelIndex]
    if channel.schedule = invalid then return
    m.scheduleChannel = channelIndex
    m.scheduleId = channel.id
    title = channel.dial + "  " + channel.name + "  ·  SCHEDULE"
    subtitle = "The next 24 hours, in your time. Press OK on REMIND ME for a reminder 15 minutes before a program starts."
    openSheet("schedule", title, subtitle, [], 0)
    m.schedItems = [{kind: "band", text: "LOADING THE NEXT 24 HOURS..."}]
    m.schedIndex = -1
    m.schedTop = 0
    m.schedList.Visible = true
    renderSchedule()
    schedule = channel.schedule
    m.scheduleTask.cueRequest = {kind: "day", id: channel.id, manifest: schedule.manifest, details: schedule.details, version: schedule.version, epochSec: schedule.epochSec, epochMsRem: schedule.epochMsRem, startIndex: schedule.startIndex, priority: true}
end sub

' "TUESDAY EVENING", "WED LATE NIGHT", as the site names parts of the day.
function dayPartLabel(sec as Integer) as String
    day = CreateObject("roDateTime")
    day.FromSeconds(sec)
    day.ToLocalTime()
    hour = day.GetHours()
    name = UCase(day.GetWeekday())
    if hour < 5 then return Left(name, 3) + " LATE NIGHT"
    if hour < 12 then return name + " MORNING"
    if hour < 17 then return name + " AFTERNOON"
    return name + " EVENING"
end function

sub onDaySchedule(result as Object)
    if m.sheetMode <> "schedule" or result.dayFor <> m.scheduleId then return
    if result.ok <> true or type(result.events) <> "roArray"
        m.schedItems = [{kind: "band", text: "COULDN'T LOAD THIS SCHEDULE. BACK, THEN SCHEDULE TO TRY AGAIN."}]
        renderSchedule()
        return
    end if
    channel = m.channels[m.scheduleChannel]
    nowSec = currentEpochSeconds()
    items = []
    band = ""
    for each event in result.events
        if event.kind = "video" and event.startSec + event.duration > nowSec and event.startSec < nowSec + 86400
            onNow = event.startSec <= nowSec
            if onNow
                label = "ON NOW"
            else
                label = dayPartLabel(event.startSec)
            end if
            if label <> band
                band = label
                items.Push({kind: "band", text: label})
            end if
            item = {kind: "program", onNow: onNow, startSec: event.startSec, duration: event.duration, title: event.title, event: event, key: reminderKey(channel.id, event.startSec)}
            item.about = scheduleAbout(channel, event)
            items.Push(item)
        end if
    end for
    if items.Count() = 0 then items.Push({kind: "band", text: "NOTHING LISTED FOR THE NEXT 24 HOURS."})
    m.schedItems = items
    m.schedTop = 0
    m.schedIndex = nextProgram(-1, 1)
    renderSchedule()
end sub

' "1992.  A season finale..." : the year, as the site shows it, then the description.
function scheduleAbout(channel as Object, event as Object) as String
    about = programDescription(channel, event)
    year = textOf(event.year)
    if year <> "" then about = year + ".  " + about
    return about
end function

' Descriptions for later programs arrive after the schedule opens.
sub refreshScheduleAbout()
    channel = m.channels[m.scheduleChannel]
    for each item in m.schedItems
        if item.kind = "program"
            item.about = scheduleAbout(channel, item.event)
            item.height = invalid
        end if
    end for
    renderSchedule()
end sub

' The next program row from index in direction (+1 / -1), or -1.
function nextProgram(index as Integer, direction as Integer) as Integer
    i = index + direction
    while i >= 0 and i < m.schedItems.Count()
        if m.schedItems[i].kind = "program" then return i
        i = i + direction
    end while
    return -1
end function

function schedHeight(item as Object) as Integer
    if item.kind = "band" then return 34
    if item.height = invalid then measureScheduleRow(item)
    return item.height + 4
end function

' How big this row's title and description must be to show in full (no "...").
' Bold text runs a little wider than the measured regular font, so the widths
' used here are narrower than the labels.
sub measureScheduleRow(item as Object)
    item.titleSize = 20
    item.titleLines = wrappedLineCount(item.title, 20, 530)
    for each size in [24, 22, 20]
        if wrappedLineCount(item.title, size, 530) = 1
            item.titleSize = size
            item.titleLines = 1
            exit for
        end if
    end for
    item.aboutLines = 0
    if item.about <> "" then item.aboutLines = wrappedLineCount(item.about, 17, 640)
    titleHeight = item.titleLines * lineHeightFor(item.titleSize)
    height = 8 + titleHeight + 4 + item.aboutLines * lineHeightFor(17) + 8
    if height < 96 then height = 96
    item.height = height
end sub

sub renderSchedule()
    count = m.schedItems.Count()
    ' Keep the focused program on screen, with its band above it when it's first.
    if m.schedIndex >= 0
        if m.schedIndex < m.schedTop then m.schedTop = m.schedIndex
        if m.schedTop = m.schedIndex and m.schedTop > 0
            if m.schedItems[m.schedTop - 1].kind = "band" then m.schedTop = m.schedTop - 1
        end if
        while true
            used = 0
            for i = m.schedTop to m.schedIndex
                used = used + schedHeight(m.schedItems[i])
            end for
            if used <= 450 or m.schedTop >= m.schedIndex then exit while
            m.schedTop = m.schedTop + 1
        end while
    end if
    y = 0
    shade = 0
    for slot = 0 to m.schedViews.Count() - 1
        view = m.schedViews[slot]
        index = m.schedTop + slot
        if index >= count or y >= 450
            view.group.Visible = false
        else
            item = m.schedItems[index]
            view.group.Visible = true
            view.group.Translation = [0, y]
            if item.kind = "band"
                view.band.Visible = true
                view.row.Visible = false
                view.bandText.Text = item.text
                shade = 0
            else
                view.band.Visible = false
                view.row.Visible = true
                fillScheduleRow(view, item, index = m.schedIndex, shade)
                shade = 1 - shade
            end if
            y = y + schedHeight(item)
        end if
    end for
    programs = 0
    position = 0
    for i = 0 to count - 1
        if m.schedItems[i].kind = "program"
            programs = programs + 1
            if i = m.schedIndex then position = programs
        end if
    end for
    if programs > 0 then m.sheetPage.Text = position.ToStr() + " OF " + programs.ToStr() else m.sheetPage.Text = ""
end sub

sub fillScheduleRow(view as Object, item as Object, focused as Boolean, shade as Integer)
    if item.onNow
        sc(view.back, "Color", "0x2A3580FF")
    else if shade = 0
        sc(view.back, "Color", "0x0A1041FF")
    else
        sc(view.back, "Color", "0x1B2869FF")
    end if
    if item.height = invalid then measureScheduleRow(item)
    view.back.Height = item.height
    view.stripe.Height = item.height
    view.stripe.Visible = item.onNow
    view.clock.Text = localTimeLabel(item.startSec)
    titleHeight = item.titleLines * lineHeightFor(item.titleSize)
    view.title.Font = "font:SmallBoldSystemFont"
    view.title.Font.Size = item.titleSize
    view.title.Wrap = item.titleLines > 1
    view.title.MaxLines = item.titleLines + 1
    view.title.Height = titleHeight
    view.title.Translation = [236, 8]
    view.title.Text = item.title
    view.length.Text = spelunkrDuration(item.duration)
    view.about.Font = "font:SmallestSystemFont"
    view.about.Font.Size = 17
    view.about.Translation = [236, 8 + titleHeight + 4]
    view.about.Height = item.aboutLines * lineHeightFor(17) + 4
    view.about.MaxLines = item.aboutLines + 1
    view.about.Text = item.about
    reminded = not item.onNow and hasReminder(item.key)
    ' The button: blue REMIND ME, orange when set, TUNE IN for what's on now.
    ' These colours are the button's own (a hair off the guide's), so each theme
    ' can give its text a colour that stands out on its face, lit or not.
    if item.onNow or reminded
        if item.onNow then view.buttonText.Text = "TUNE IN" else view.buttonText.Text = "REMINDER SET"
        faceTop = "0xD2640EFF"
        faceBottom = "0xB0480BFF"
        textColor = "0xFFE22FFF"
        if focused then faceTop = "0xE0700EFF"
    else
        view.buttonText.Text = "REMIND ME"
        faceTop = "0x4A50F0FF"
        faceBottom = "0x2B2FC5FF"
        textColor = "0xFFFFFFFF"
        if focused
            faceTop = "0x6A70FFFF"
            faceBottom = "0x6A70FFFF"
            textColor = "0xFFFFFEFF"
        end if
    end if
    sc(view.buttonText, "Color", textColor)
    if focused
        ' Lit up: brighter face, pale outline and a soft glow around it.
        sc(view.outline, "Color", "0xFFF6A0FF")
    else
        sc(view.outline, "Color", "0x14153AFF")
    end if
    sc(view.faceTop, "Color", faceTop)
    sc(view.faceBottom, "Color", faceBottom)
    view.glow.Visible = focused
end sub

function onScheduleKey(key as String) as Boolean
    if key = "up" or key = "down"
        direction = 1
        if key = "up" then direction = -1
        target = nextProgram(m.schedIndex, direction)
        if target >= 0
            m.schedIndex = target
        else if key = "up"
            m.schedTop = 0
        end if
        renderSchedule()
    else if key = "rewind" or key = "fastforward"
        for i = 1 to 4
            if key = "rewind" then target = nextProgram(m.schedIndex, -1) else target = nextProgram(m.schedIndex, 1)
            if target >= 0 then m.schedIndex = target
        end for
        renderSchedule()
    else if key = "OK"
        if m.schedIndex >= 0
            item = m.schedItems[m.schedIndex]
            if item.onNow
                index = m.scheduleChannel
                closeSheet()
                if m.directoryOpen then selectDirectoryChannel(index, true)
            else
                toggleScheduleReminder(item)
            end if
        end if
    else if key = "back" or key = "replay"
        closeSheet()
    end if
    return true
end function

sub toggleScheduleReminder(item as Object)
    channel = m.channels[m.scheduleChannel]
    if hasReminder(item.key)
        removeReminder(item.key)
    else
        m.reminders.Push({key: item.key, id: channel.id, dial: channel.dial, name: channel.name, title: item.title, startSec: item.startSec, alerted: false})
        saveReminders()
    end if
    renderSchedule()
end sub

' ---- Quick channel switch (Replay in full screen) -------------------------------
' A narrow list on the left: the video keeps playing the same channel while you
' look; OK switches, Back or Replay closes with nothing changed.

sub openQuick()
    count = m.channels.Count()
    if count = 0 then return
    closeSyncPanel()
    hidePlaybackBanner()
    hideChannelOsd()
    m.quickOpen = true
    m.quickFavOnly = false
    buildQuickList()
    m.quickPanel.Visible = true
    requestQuickSchedules()
    renderQuick()
    m.quickTimer.Control = "stop"
    m.quickTimer.Control = "start"
end sub

sub closeQuick()
    m.quickOpen = false
    m.quickPanel.Visible = false
    m.quickTimer.Control = "stop"
end sub

' The channels the quick list shows: every channel, or only favorites.
sub buildQuickList()
    m.quickList = []
    for i = 0 to m.channels.Count() - 1
        if not m.quickFavOnly or isFavorite(m.channels[i]) then m.quickList.Push(i)
    end for
    m.quickPos = 0
    for i = 0 to m.quickList.Count() - 1
        if m.quickList[i] = m.currentIndex then m.quickPos = i
    end for
end sub

sub renderQuick()
    count = m.quickList.Count()
    if m.quickFavOnly then m.quickTitle.Text = "FAVORITES" else m.quickTitle.Text = "CHANNELS"
    ' A long list keeps the highlight in the middle row and wraps; a short one
    ' (a few favorites) lists from the top.
    wrap = count >= 9
    for slot = 0 to 8
        view = m.quickViews[slot]
        position = slot
        if wrap then position = ((m.quickPos - 4 + slot) mod count + count) mod count
        if position >= count or count = 0
            view.group.Visible = false
        else
            view.group.Visible = true
            index = m.quickList[position]
            channel = m.channels[index]
            view.dial.Text = channel.dial
            view.logo.Uri = channel.logoUri
            view.star.Visible = isFavorite(channel)
            if view.name.Text <> channel.name then fitLabel(view.name, channel.name, "font:SmallBoldSystemFont", [22, 20, 18, 16, 14], 264, 28)
            playing = ""
            if channel.timelineLoaded
                refreshChannelSchedule(channel)
                if channel.now <> invalid
                    if channel.now.kind = "video" then playing = channel.now.title else if channel.next <> invalid then playing = channel.next.title
                end if
            end if
            if index = m.currentIndex and playing <> "" then playing = "WATCHING  ·  " + playing
            if view.playing.Text <> playing then fitLabel(view.playing, playing, "font:SmallestSystemFont", [16, 14, 13, 12], 264, 34)
        end if
    end for
    highlight = 4
    if not wrap then highlight = m.quickPos
    m.quickHighlight.Visible = count > 0
    m.quickHighlight.Translation = [0, 58 + highlight * 64]
end sub

function onQuickKey(key as String) as Boolean
    m.quickTimer.Control = "stop"
    m.quickTimer.Control = "start"
    count = m.quickList.Count()
    if key = "up" and count > 0
        m.quickPos = (m.quickPos - 1 + count) mod count
        renderQuick()
    else if key = "down" and count > 0
        m.quickPos = (m.quickPos + 1) mod count
        renderQuick()
    else if key = "left" or key = "right"
        if m.favorites.Count() = 0
            m.quickTitle.Text = "NO FAVORITES YET  ·  ADD THEM IN OPTIONS"
        else
            m.quickFavOnly = not m.quickFavOnly
            buildQuickList()
            renderQuick()
        end if
    else if key = "OK" and count > 0
        index = m.quickList[m.quickPos]
        closeQuick()
        if index <> m.currentIndex then fullscreenTune(index) else showPlaybackBanner()
    else if key = "back" or key = "replay"
        closeQuick()
    else if key = "play"
        togglePause()
    else if key = "options"
        return false
    end if
    return true
end function

' Listings for every channel, nearest the playing one first, so the list's
' now-playing lines fill in.
sub requestQuickSchedules()
    if m.scheduleTask = invalid then return
    count = m.channels.Count()
    horizon = m.hourStartSec + 14400
    queue = []
    for offset = 0 to count - 1
        if offset mod 2 = 0 then step2 = Int(offset / 2) else step2 = -Int((offset + 1) / 2)
        addScheduleRequest(queue, ((m.currentIndex + step2) mod count + count) mod count, offset < 10, horizon)
    end for
    if queue.Count() > 0 then m.scheduleTask.scheduleQueue = queue
end sub

' Plays another channel full screen (the quick list and reminders), the same
' way Up/Down flip channels.
sub fullscreenTune(target as Integer)
    count = m.channels.Count()
    if count = 0 or target < 0 or target >= count then return
    closeSyncPanel()
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
