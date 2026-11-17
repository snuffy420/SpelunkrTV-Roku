' ---- Viewer settings and favorites (Options) --------------------------------------
' Each setting cycles through its choices with OK in the Options sheet and is
' remembered. Favorites are marked in Options for the channel you're on; a small
' gold star sits on their logo in the guide, the directory and the quick list,
' and Left/Right in the quick list switch between all channels and favorites.

function settingList() as Object
    return [
        {id: "startOn", label: "Start on", fallback: "last", choices: [{v: "last", t: "LAST CHANNEL"}, {v: "favorite", t: "FIRST FAVORITE"}, {v: "first", t: "FIRST CHANNEL"}]},
        {id: "clock", label: "Clock", fallback: "12", choices: [{v: "12", t: "12-HOUR"}, {v: "24", t: "24-HOUR"}]},
        {id: "tempUnit", label: "Weather temperature", fallback: "F", choices: [{v: "F", t: Chr(176) + "F"}, {v: "C", t: Chr(176) + "C"}]},
        {id: "preview", label: "Guide preview", fallback: "sound", choices: [{v: "sound", t: "ON"}, {v: "muted", t: "MUTED"}, {v: "off", t: "OFF"}]},
        {id: "scanSpeed", label: "Scan speed", fallback: "normal", choices: [{v: "slow", t: "SLOW"}, {v: "normal", t: "NORMAL"}, {v: "fast", t: "FAST"}]},
        {id: "subtitles", label: "Subtitles (when a tape has them)", fallback: "on", choices: [{v: "on", t: "ON"}, {v: "off", t: "OFF"}]},
        {id: "idle", label: "Screensaver after", fallback: "5", choices: [{v: "5", t: "5 MIN"}, {v: "15", t: "15 MIN"}, {v: "30", t: "30 MIN"}]}
    ]
end function

sub initSettings()
    m.clock24 = loadSetting("clock", "12") = "24"
    m.previewMode = loadSetting("preview", "sound")
    m.idleSeconds = Val(loadSetting("idle", "5")) * 60
    if m.idleSeconds < 60 then m.idleSeconds = 300
    applyScanSpeed()
    m.favorites = {}
    stored = ParseJson(loadSetting("favorites", "[]"))
    if type(stored) = "roArray"
        for each id in stored
            m.favorites[id] = true
        end for
    end if
end sub

function settingValue(setting as Object) as String
    return loadSetting(setting.id, setting.fallback)
end function

function settingText(setting as Object) as String
    value = settingValue(setting)
    for each choice in setting.choices
        if choice.v = value then return choice.t
    end for
    return setting.choices[0].t
end function

' OK on a setting: the next choice, saved and applied at once.
sub cycleSetting(id as String)
    for each setting in settingList()
        if setting.id = id
            value = settingValue(setting)
            upcoming = setting.choices[0].v
            for i = 0 to setting.choices.Count() - 1
                if setting.choices[i].v = value then upcoming = setting.choices[(i + 1) mod setting.choices.Count()].v
            end for
            saveSetting(id, upcoming)
            applySetting(id, upcoming)
        end if
    end for
end sub

sub applySetting(id as String, value as String)
    if id = "clock"
        m.clock24 = value = "24"
        ' Redraw the clock and the time headings now.
        m.lastMinute = -1
        m.hourStartSec = -1
        onTick()
    else if id = "preview"
        m.previewMode = value
        applyPreviewMode()
    else if id = "scanSpeed"
        applyScanSpeed()
    else if id = "subtitles"
        m.subtitlesOn = value = "on"
        updateSubtitleTimer()
    else if id = "idle"
        m.idleSeconds = Val(value) * 60
    else if id = "tempUnit"
        requestWeather()
    end if
end sub

sub applyScanSpeed()
    speed = loadSetting("scanSpeed", "normal")
    roll = 4
    feature = 45
    if speed = "slow"
        roll = 6
        feature = 60
    else if speed = "fast"
        roll = 3
        feature = 30
    end if
    if m.rollTimer <> invalid then m.rollTimer.Duration = roll
    if m.featureTimer <> invalid then m.featureTimer.Duration = feature
end sub

' The guide preview: with sound, muted, or off (no stream until full screen).
sub applyPreviewMode()
    if m.fullscreen then return
    if m.previewMode = "off"
        previewOff()
    else
        m.previewVideo.Mute = m.previewMode = "muted"
        if m.previewNotice = "PREVIEW OFF"
            m.previewNotice = ""
            if m.active then startPreview(m.channels[m.currentIndex])
        end if
    end if
end sub

sub previewOff()
    stopPreview()
    showStatic()
    m.previewNotice = "PREVIEW OFF"
    updateTuningBadge(currentEpochSeconds())
end sub

' A time of day in the viewer's chosen clock: "7:30 PM" or "19:30".
function clockText(hour as Integer, minute as Integer) as String
    minutes = minute.ToStr()
    if Len(minutes) = 1 then minutes = "0" + minutes
    if m.clock24 = true
        hours = hour.ToStr()
        if Len(hours) = 1 then hours = "0" + hours
        return hours + ":" + minutes
    end if
    suffix = "AM"
    if hour >= 12 then suffix = "PM"
    hour = hour mod 12
    if hour = 0 then hour = 12
    return hour.ToStr() + ":" + minutes + " " + suffix
end function

' Where the guide opens: the last channel watched full screen, the first
' favorite, or the first channel.
function startChannelIndex() as Integer
    choice = loadSetting("startOn", "last")
    if choice = "last"
        id = loadSetting("lastChannel", "")
        if id <> "" and m.channelIndexById.DoesExist(id) then return m.channelIndexById[id]
    else if choice = "favorite"
        for i = 0 to m.channels.Count() - 1
            if m.favorites.DoesExist(m.channels[i].id) then return i
        end for
    end if
    return 0
end function

sub rememberLastChannel(channel as Object)
    if m.lastSavedChannel = channel.id then return
    m.lastSavedChannel = channel.id
    saveSetting("lastChannel", channel.id)
end sub

' ---- Favorites -----------------------------------------------------------------

function isFavorite(channel as Object) as Boolean
    return m.favorites.DoesExist(channel.id)
end function

sub toggleFavorite(channel as Object)
    if isFavorite(channel) then m.favorites.Delete(channel.id) else m.favorites[channel.id] = true
    ids = []
    for each id in m.favorites
        ids.Push(id)
    end for
    saveSetting("favorites", FormatJson(ids))
    renderGuideRows()
end sub

' The star on a logo's corner.
function addFavoriteStar(parent as Object, x as Integer, y as Integer, size as Integer) as Object
    star = parent.CreateChild("Poster")
    star.Uri = "pkg:/images/favorite-star.png"
    star.Translation = [x, y]
    star.Width = size
    star.Height = size
    star.Visible = false
    return star
end function

' ---- Weather in the guide header ------------------------------------------------
' Off until a ZIP code is entered in Options; then the centre of the header shows
' an icon, the temperature and the conditions, refreshed every 30 minutes.

sub initWeather()
    m.weatherGroup = m.top.FindNode("weatherGroup")
    m.weatherIcon = m.top.FindNode("weatherIcon")
    m.weatherText = m.top.FindNode("weatherText")
    m.weatherShown = false
    ' Status messages share the header's centre: weather hides the moment one
    ' appears and returns when it clears.
    m.status.ObserveField("text", "updateWeatherVisible")
    ' The first reading waits a moment for the listings worker to be ready.
    m.weatherStartTimer = makeTimer(5, false, "requestWeather")
end sub

function weatherZip() as String
    return loadSetting("zip", "")
end function

sub requestWeather()
    zip = weatherZip()
    if zip = ""
        m.weatherShown = false
        m.weatherGroup.Visible = false
        return
    end if
    if m.scheduleTask = invalid then return
    m.scheduleTask.cueRequest = {kind: "weather", zip: zip, country: loadSetting("zipCountry", "US"), unit: loadSetting("tempUnit", "F")}
end sub

sub onWeather(weather as Object)
    if weatherZip() = "" then return
    if weather.ok <> true
        ' A bad ZIP says so; a network hiccup keeps the last reading.
        if weather.reason = "zip"
            m.weatherIcon.Uri = ""
            m.weatherText.Text = "LOCATION NOT FOUND"
            m.weatherShown = true
        end if
        updateWeatherVisible()
        return
    end if
    code = Int(weather.code)
    day = weather.day = 1
    info = weatherLook(code, day)
    m.weatherIcon.Uri = "pkg:/images/weather/" + info.icon + ".png"
    m.weatherText.Text = Int(weather.temp + 0.5).ToStr() + Chr(176) + loadSetting("tempUnit", "F") + "  " + info.text
    m.weatherShown = true
    updateWeatherVisible()
end sub

' The header's centre also carries status messages; weather steps aside for them.
sub updateWeatherVisible()
    m.weatherGroup.Visible = m.weatherShown and m.status.Text = "" and m.active
end sub

' WMO weather codes (Open-Meteo) to an icon and a few words.
function weatherLook(code as Integer, day as Boolean) as Object
    time = "night"
    if day then time = "day"
    if code = 0
        if day then return {icon: "clear-day", text: "SUNNY"}
        return {icon: "clear-night", text: "CLEAR"}
    else if code = 1
        return {icon: "clear-" + time, text: "MOSTLY CLEAR"}
    else if code = 2
        return {icon: "partly-" + time, text: "PARTLY CLOUDY"}
    else if code = 3
        return {icon: "cloudy", text: "CLOUDY"}
    else if code = 45 or code = 48
        return {icon: "fog", text: "FOG"}
    else if code >= 51 and code <= 55
        return {icon: "drizzle", text: "DRIZZLE"}
    else if code = 56 or code = 57
        return {icon: "drizzle", text: "FREEZING DRIZZLE"}
    else if code = 61 or code = 63
        return {icon: "rain", text: "RAIN"}
    else if code = 65
        return {icon: "rain", text: "HEAVY RAIN"}
    else if code = 66 or code = 67
        return {icon: "rain", text: "FREEZING RAIN"}
    else if code = 71 or code = 73 or code = 77
        return {icon: "snow", text: "SNOW"}
    else if code = 75
        return {icon: "snow", text: "HEAVY SNOW"}
    else if code = 80 or code = 81
        return {icon: "rain", text: "SHOWERS"}
    else if code = 82
        return {icon: "rain", text: "HEAVY SHOWERS"}
    else if code = 85 or code = 86
        return {icon: "snow", text: "SNOW SHOWERS"}
    else if code >= 95
        return {icon: "thunder", text: "THUNDERSTORMS"}
    end if
    return {icon: "cloudy", text: ""}
end function

' Options > Weather: our own entry pad for a ZIP or postcode, in the theme's
' colours. A COUNTRY button on top (the countries Zippopotam.us covers), the
' code above the keys, then a number pad, or with ABC a QWERTY keyboard for
' postcodes with letters. Arrows move, OK presses, Replay deletes, Play saves,
' Back cancels.
function zipCountries() as Object
    return ["US", "CA", "MX", "GB", "IE", "AU", "NZ", "DE", "FR", "NL", "BE", "LU", "ES", "PT", "IT", "CH", "AT", "SE", "NO", "DK", "FI", "IS", "PL", "CZ", "SK", "HU", "SI", "HR", "RO", "BG", "GR", "TR", "BR", "AR", "CL", "CO", "PE", "EC", "UY", "PY", "BO", "VE", "CR", "PA", "GT", "HN", "SV", "NI", "DO", "PR", "JM", "TT", "BS", "BB", "JP", "KR", "TW", "HK", "SG", "MY", "TH", "PH", "ID", "VN", "IN", "PK", "AE", "SA", "IL", "EG", "ZA", "NG", "KE", "RU", "UA"]
end function

sub buildZipPad()
    m.zipPad = m.top.FindNode("zipPad")
    m.zipNote = m.top.FindNode("zipNote")
    m.zipField = m.top.FindNode("zipField")
    m.zipCursor = m.top.FindNode("zipCursor")
    m.zipKeysGroup = m.top.FindNode("zipKeys")
    m.zipOpen = false
    m.zipMode = "num"
    buildHintRow("zipHints", [{icons: ["dpad-all"], text: "MOVE"}, {icons: ["ok"], text: "PRESS"}, {icons: ["replay"], text: "DELETE"}, {icons: ["playpause"], text: "SAVE"}, {icons: ["back"], text: "CANCEL"}], true)
end sub

' The rows of keys for a mode: each key {label, x, w}. Row 0 is COUNTRY.
function zipRows(mode as String) as Object
    rows = [[{label: "COUNTRY", x: 150, w: 300}]]
    if mode = "num"
        layout = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["ABC", "0", "DELETE"]]
        for each line in layout
            row = []
            for i = 0 to 2
                row.Push({label: line[i], x: 90 + i * 144, w: 132})
            end for
            rows.Push(row)
        end for
        rows.Push([{label: "TURN OFF", x: 90, w: 132}, {label: "SAVE", x: 234, w: 276}])
    else
        for each line in ["1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
            row = []
            offset = Int((10 - Len(line)) * 26)
            for i = 0 to Len(line) - 1
                row.Push({label: Mid(line, i + 1, 1), x: 43 + offset + i * 52, w: 46})
            end for
            rows.Push(row)
        end for
        rows.Push([{label: "123", x: 43, w: 94}, {label: "-", x: 143, w: 46}, {label: "SPACE", x: 195, w: 150}, {label: "DELETE", x: 351, w: 104}, {label: "CLEAR", x: 461, w: 96}])
        rows.Push([{label: "TURN OFF", x: 43, w: 254}, {label: "SAVE", x: 303, w: 254}])
    end if
    return rows
end function

' Draws the keys for the current mode (rebuilt when ABC / 123 switches).
sub buildZipKeys()
    while m.zipKeysGroup.GetChildCount() > 0
        m.zipKeysGroup.RemoveChildIndex(0)
    end while
    m.zipRowsNow = zipRows(m.zipMode)
    m.zipKeyViews = []
    rowStep = 52
    height = 44
    if m.zipMode = "num"
        rowStep = 56
        height = 46
    end if
    for r = 0 to m.zipRowsNow.Count() - 1
        views = []
        for each key in m.zipRowsNow[r]
            y = r * rowStep
            if r > 0 then y = y + 70
            glow = m.zipKeysGroup.CreateChild("Rectangle")
            glow.Translation = [key.x - 5, y - 5]
            glow.Width = key.w + 10
            glow.Height = height + 10
            sc(glow, "Color", "0xFFD74055")
            outline = m.zipKeysGroup.CreateChild("Rectangle")
            outline.Translation = [key.x, y]
            outline.Width = key.w
            outline.Height = height
            faceTop = m.zipKeysGroup.CreateChild("Rectangle")
            faceTop.Translation = [key.x + 2, y + 2]
            faceTop.Width = key.w - 4
            faceTop.Height = Int(height / 2) - 2
            faceBottom = m.zipKeysGroup.CreateChild("Rectangle")
            faceBottom.Translation = [key.x + 2, y + Int(height / 2)]
            faceBottom.Width = key.w - 4
            faceBottom.Height = height - Int(height / 2) - 2
            text = m.zipKeysGroup.CreateChild("Label")
            text.Translation = [key.x, y]
            text.Width = key.w
            text.Height = height
            text.HorizAlign = "center"
            text.VertAlign = "center"
            if Len(key.label) = 1 then text.Font = "font:MediumBoldSystemFont" else text.Font = "font:SmallBoldSystemFont"
            text.Text = key.label
            views.Push({glow: glow, outline: outline, faceTop: faceTop, faceBottom: faceBottom, text: text, label: key.label, x: key.x, w: key.w})
        end for
        m.zipKeyViews.Push(views)
    end for
end sub

sub openZipPad()
    m.zipDigits = weatherZip()
    m.zipCountry = loadSetting("zipCountry", "")
    if m.zipCountry = ""
        ' Start on the Roku's own country when the lookup covers it.
        ' The Roku's own country, whatever it is (the place search covers nearly all).
        here = UCase(CreateObject("roDeviceInfo").GetUserCountryCode())
        m.zipCountry = "US"
        if Len(here) = 2 then m.zipCountry = here
    end if
    ' Letters in the saved code: open on the keyboard.
    m.zipMode = "num"
    for i = 1 to Len(m.zipDigits)
        if Instr(1, "0123456789", Mid(m.zipDigits, i, 1)) = 0 then m.zipMode = "abc"
    end for
    buildZipKeys()
    m.zipRow = 1
    m.zipCol = 0
    zipNoteText("Your ZIP, postcode or town for the weather.")
    m.sheet.Visible = false
    m.zipOpen = true
    m.zipPad.Visible = true
    renderZipPad()
end sub

sub zipNoteText(text as String)
    fitLabel(m.zipNote, text, "font:SmallestSystemFont", [17, 16, 15, 14, 13], 544, 48)
end sub

sub closeZipPad()
    m.zipOpen = false
    m.zipPad.Visible = false
    m.sheet.Visible = true
    if m.sheetMode = "options"
        index = m.sheetIndex
        top = m.sheetTop
        openOptions()
        m.sheetIndex = index
        m.sheetTop = top
        renderSheet()
    end if
end sub

sub renderZipPad()
    fitLabel(m.zipField, m.zipDigits, "font:LargeBoldSystemFont", [36, 32, 28, 24, 20], 284, 56)
    width = 0
    if m.zipDigits <> "" then width = m.zipField.BoundingRect().width
    m.zipCursor.Translation = [300 + Int(width / 2) + 4, 168]
    for r = 0 to m.zipKeyViews.Count() - 1
        for c = 0 to m.zipKeyViews[r].Count() - 1
            view = m.zipKeyViews[r][c]
            focused = r = m.zipRow and c = m.zipCol
            label = view.label
            if label = "COUNTRY"
                view.text.Text = "COUNTRY  ·  " + m.zipCountry
            end if
            ' SAVE, TURN OFF and the mode switch are the orange buttons, the
            ' rest blue: the colours of REMIND ME and TUNE IN in the schedule.
            if label = "SAVE" or label = "TURN OFF" or label = "ABC" or label = "123" or label = "COUNTRY"
                faceTop = "0xD2640EFF"
                if focused then faceTop = "0xE0700EFF"
                sc(view.faceTop, "Color", faceTop)
                sc(view.faceBottom, "Color", "0xB0480BFF")
                sc(view.text, "Color", "0xFFE22FFF")
            else
                faceTop = "0x4A50F0FF"
                textColor = "0xFFFFFFFF"
                faceBottom = "0x2B2FC5FF"
                if focused
                    faceTop = "0x6A70FFFF"
                    faceBottom = "0x6A70FFFF"
                    textColor = "0xFFFFFEFF"
                end if
                sc(view.faceTop, "Color", faceTop)
                sc(view.faceBottom, "Color", faceBottom)
                sc(view.text, "Color", textColor)
            end if
            if focused then sc(view.outline, "Color", "0xFFF6A0FF") else sc(view.outline, "Color", "0x14153AFF")
            view.glow.Visible = focused
        end for
    end for
end sub

' Up/Down land on the key nearest above or below; Left/Right walk the row
' (on COUNTRY they change the country).
function onZipKey(key as String) as Boolean
    if key = "up" or key = "down"
        target = m.zipRow - 1
        if key = "down" then target = m.zipRow + 1
        if target >= 0 and target < m.zipKeyViews.Count()
            here = m.zipKeyViews[m.zipRow][m.zipCol]
            middle = here.x + here.w / 2
            best = 0
            bestGap = 99999
            for c = 0 to m.zipKeyViews[target].Count() - 1
                view = m.zipKeyViews[target][c]
                gap = Abs(view.x + view.w / 2 - middle)
                if gap < bestGap
                    bestGap = gap
                    best = c
                end if
            end for
            m.zipRow = target
            m.zipCol = best
        end if
    else if key = "left" or key = "right"
        if m.zipRow = 0
            stepCountry(key = "right")
        else if key = "left" and m.zipCol > 0
            m.zipCol = m.zipCol - 1
        else if key = "right" and m.zipCol < m.zipKeyViews[m.zipRow].Count() - 1
            m.zipCol = m.zipCol + 1
        end if
    else if key = "OK"
        pressZipKey(m.zipKeyViews[m.zipRow][m.zipCol].label)
        return true
    else if key = "replay"
        pressZipKey("DELETE")
        return true
    else if key = "play"
        pressZipKey("SAVE")
        return true
    else if key = "back"
        closeZipPad()
        return true
    end if
    renderZipPad()
    return true
end function

sub stepCountry(forward as Boolean)
    list = zipCountries()
    index = -1
    for i = 0 to list.Count() - 1
        if list[i] = m.zipCountry then index = i
    end for
    if index < 0 then index = 0 else if forward then index = (index + 1) mod list.Count() else index = (index - 1 + list.Count()) mod list.Count()
    m.zipCountry = list[index]
end sub

sub pressZipKey(label as String)
    if label = "COUNTRY"
        stepCountry(true)
    else if label = "ABC" or label = "123"
        if label = "ABC" then m.zipMode = "abc" else m.zipMode = "num"
        buildZipKeys()
        ' Back on the mode key in its new place.
        m.zipRow = m.zipKeyViews.Count() - 2
        m.zipCol = 0
        if m.zipMode = "num" then m.zipRow = 4
    else if label = "DELETE"
        if Len(m.zipDigits) > 0 then m.zipDigits = Left(m.zipDigits, Len(m.zipDigits) - 1)
    else if label = "CLEAR"
        m.zipDigits = ""
    else if label = "TURN OFF"
        saveWeatherZip("")
        return
    else if label = "SAVE"
        code = m.zipDigits.Trim()
        if code = ""
            saveWeatherZip("")
            return
        end if
        digits = true
        for i = 1 to Len(code)
            if Instr(1, "0123456789", Mid(code, i, 1)) = 0 then digits = false
        end for
        if m.zipCountry = "US" and digits and Len(code) <> 5
            zipNoteText("A US ZIP code has 5 digits.")
        else if Len(code) < 2
            zipNoteText("That's too short for a postcode or town.")
        else
            saveWeatherZip(code)
            return
        end if
    else if label = "SPACE"
        if Len(m.zipDigits) < 24 and Right(m.zipDigits, 1) <> " " and m.zipDigits <> "" then m.zipDigits = m.zipDigits + " "
    else if Len(m.zipDigits) < 24
        m.zipDigits = m.zipDigits + label
    end if
    renderZipPad()
end sub

sub saveWeatherZip(code as String)
    saveSetting("zip", code)
    saveSetting("zipCountry", m.zipCountry)
    if code = "" then m.weatherShown = false
    requestWeather()
    closeZipPad()
end sub

