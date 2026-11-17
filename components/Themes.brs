' ---- Themes ------------------------------------------------------------------
' Classic is the app as drawn in MainScene.xml and MainScene.brs. Another theme
' maps each Classic colour to its own, swaps the background and header images
' and lays rounded panel frames (images/themes, made by tools/build_themes.py)
' over the flat panels.
'
' Every coloured node remembers its Classic colour in a "tb" field: nodes from
' the XML get it on the first walk, nodes made in code get it from sc(). So a
' theme can be changed at any time and changed back.

function themeList() as Object
    return [
        {id: "classic", name: "Classic", note: "the original look"},
        {id: "glass", name: "Glass", note: "frosted 3D panels"},
        {id: "neon", name: "Neon", note: "glowing outlines"},
        {id: "afterglow", name: "Spelunkr Neon", note: "orange and blue glow"},
        {id: "channel", name: "Channel Color", note: "follows each channel"}
    ]
end function

' Classic colour (hex digits, upper case) -> theme colour.
function themeColors(id as String) as Object
    if id = "channel" then return channelPalette(m.channelTint)
    if id = "glass"
        return {
            "1B2868FF": "00000000", "0A1040FF": "00000000", "344A91FF": "FFFFFF22", "A64310FF": "E0701AD8",
            "060B1EFF": "060B1EC8", "060B1ECC": "0A0C1ED8", "4A5AAAFF": "00000000", "2A3580FF": "FFFFFF26",
            "FFD740FF": "FFD34DFF", "FFD740E6": "FFD34DFF", "FFE22EFF": "FFD34DFF", "00CCDDEE": "8FF0FFFF",
            "E8EAF0FF": "EEF1FFFF", "C7D2F2FF": "CFD5F5FF", "7788BB66": "FFFFFF26", "7788BB33": "FFFFFF12",
            "00000048": "0000005C", "2B2FC4FF": "FFFFFF30", "2226A0FF": "FFFFFF1C", "D2640FFF": "FF9B45FF",
            "B0480AFF": "E0601AFF", "14153AFF": "0B0E1D90", "3157A5FF": "FFFFFF38", "1F2A6BFF": "1A1F45E0",
            "99A3CCFF": "B9C1FFFF", "B9B0E8FF": "B9C1FFFF", "B8500EFF": "E0601AFF", "E0700FFF": "FF9B45FF",
            "4A50F0FF": "8090FFFF", "FFF6A0FF": "FFE9A0FF", "07112BEE": "0B0E1DD8",
            "07112BF4": "141836FF", "07112BFF": "141836FF", "27334FFF": "FFFFFF26", "000000FF": "00000080", "1A0B4BFF": "1A1F45E0",
            "FFD74055": "FFD34D66", "6A70FFFF": "A0ACFFFF", "2B2FC5FF": "5E6CD8FF", "0A1041FF": "FFFFFF0A", "1B2869FF": "FFFFFF18", "FFFFFEFF": "141836FF",
            "D2640EFF": "FF9B45FF", "B0480BFF": "E0601AFF", "E0700EFF": "FFB066FF", "FFE22FFF": "1B1240FF"
        }
    else if id = "neon"
        return {
            "1B2868FF": "00000000", "0A1040FF": "00000000", "344A91FF": "33F0FF1C", "A64310FF": "FF3FD058",
            "060B1EFF": "000000FF", "060B1ECC": "000000D8", "4A5AAAFF": "00000000", "2A3580FF": "33F0FF66",
            "FFD740FF": "F8FF3AFF", "FFD740E6": "F8FF3AFF", "FFE22EFF": "F8FF3AFF", "00CCDDEE": "33F0FFFF",
            "E8EAF0FF": "F1EAFFFF", "C7D2F2FF": "CFC7E6FF", "7788BB66": "33F0FF40", "7788BB33": "33F0FF1E",
            "00000048": "00000070", "2B2FC4FF": "33F0FF30", "2226A0FF": "33F0FF18", "D2640FFF": "F8FF3A70",
            "B0480AFF": "F8FF3A48", "14153AFF": "000000FF", "3157A5FF": "33F0FFAA", "1F2A6BFF": "0A0814FF",
            "99A3CCFF": "A79FC8FF", "B9B0E8FF": "FF8FE6FF", "B8500EFF": "FF3FD066", "E0700FFF": "FF3FD0B8",
            "4A50F0FF": "33F0FF88", "FFF6A0FF": "F8FF3AFF", "07112BEE": "05040BE8", "07112BF4": "05040BF6", "07112BFF": "05040BFF",
            "27334FFF": "33F0FF30", "000000FF": "000000FF", "1A0B4BFF": "0A0814FF",
            "FFD74055": "F8FF3A55", "6A70FFFF": "33F0FFFF", "2B2FC5FF": "0E5E6CFF", "0A1041FF": "33F0FF0C", "1B2869FF": "33F0FF1C", "FFFFFEFF": "000000FF",
            "D2640EFF": "FF3FD0C8", "B0480BFF": "FF3FD090", "E0700EFF": "FF6FDCFF", "FFE22FFF": "FFFFFFFF"
        }
    else if id = "afterglow"
        ' Spelunkr Neon: near-black, Spelunkr's orange for what's live and lit,
        ' its blue for outlines and listings.
        return {
            "1B2868FF": "00000000", "0A1040FF": "00000000", "344A91FF": "3D6BFF1E", "A64310FF": "FF7A1A60",
            "060B1EFF": "000000FF", "060B1ECC": "000000D8", "4A5AAAFF": "00000000", "2A3580FF": "3D6BFF66",
            "FFD740FF": "FF9A2EFF", "FFD740E6": "FF9A2EFF", "FFE22EFF": "FFB547FF", "00CCDDEE": "6FA8FFFF",
            "E8EAF0FF": "F2F0FFFF", "C7D2F2FF": "C9CFEAFF", "7788BB66": "3D6BFF44", "7788BB33": "3D6BFF20",
            "00000048": "00000070", "2B2FC4FF": "3D6BFF40", "2226A0FF": "3D6BFF22", "D2640FFF": "FF7A1A80",
            "B0480AFF": "FF7A1A58", "14153AFF": "000000FF", "3157A5FF": "3D6BFFAA", "1F2A6BFF": "070A18FF",
            "99A3CCFF": "9AA6D8FF", "B9B0E8FF": "FFB066FF", "B8500EFF": "FF7A1A70", "E0700FFF": "FF7A1AC0",
            "4A50F0FF": "3D6BFF99", "FFF6A0FF": "FFB547FF", "07112BEE": "03040CE8", "07112BF4": "05060FFF", "07112BFF": "05060FFF",
            "27334FFF": "3D6BFF30", "000000FF": "000000FF", "1A0B4BFF": "070A18FF",
            "FFD74055": "FF7A1A60", "6A70FFFF": "7FA2FFFF", "2B2FC5FF": "2447C8FF", "0A1041FF": "3D6BFF10", "1B2869FF": "3D6BFF22", "FFFFFEFF": "05060FFF",
            "D2640EFF": "FF7A1AFF", "B0480BFF": "D85E08FF", "E0700EFF": "FFA040FF", "FFE22FFF": "120800FF"
        }
    end if
    return {}
end function

function themeImages(id as String) as Object
    if id = "glass" or id = "neon" or id = "afterglow" or id = "channel"
        return {"guide-background.png": "themes/" + id + "-background.png", "header-gradient.png": "themes/" + id + "-header.png"}
    end if
    return {}
end function

' A colour in the current theme. Colours a theme doesn't list stay as they are.
function tc(classic as String) as String
    if m.themeMap = invalid then return classic
    key = UCase(Mid(classic, 3))
    if m.themeMap.DoesExist(key) then return "0x" + m.themeMap[key]
    return classic
end function

' Sets a node's colour field from a Classic colour, remembering it for later
' theme changes. field: "Color" (Rectangle, Label) or "BlendColor" (Poster).
sub sc(node as Object, field as String, classic as String)
    if not node.HasField("tb")
        node.AddField("tb", "string", false)
        themeRegister(node, field)
    end if
    node.tb = classic
    node[field] = tc(classic)
end sub

sub themeRegister(node as Object, field as String)
    if m.themeNodes = invalid then m.themeNodes = []
    m.themeNodes.Push({node: node, field: field})
end sub

sub loadTheme()
    m.themeId = loadSetting("theme", "classic")
    valid = false
    for each theme in themeList()
        if theme.id = m.themeId then valid = true
    end for
    if not valid then m.themeId = "classic"
    m.themeMap = themeColors(m.themeId)
end sub

sub applyTheme(id as String)
    m.themeId = id
    if id = "channel"
        ' Start from the channel you're on (or Spelunkr orange before the lineup loads).
        if m.channels <> invalid and m.channels.Count() > m.currentIndex then m.channelTint = spelunkrColor(m.channels[m.currentIndex].color)
        if m.channelTint = invalid then m.channelTint = "0xD2640FFF"
    end if
    m.themeMap = themeColors(id)
    m.themeUris = themeImages(id)
    if m.themeBackdrops = invalid then m.themeBackdrops = []
    themeWalk(m.top)
    themeFrames()
    themeBackdropTint()
    ' Flat 3 px panel edges belong to Classic and Channel Color (they take the
    ' channel's colour); the other themes draw rounded frames.
    classic = id = "classic" or id = "channel"
    for each edge in m.accentEdges
        if edge <> invalid and edge.id <> "headerRule" then edge.Visible = classic
    end for
end sub

sub themeWalk(node as Object)
    kind = node.Subtype()
    if kind = "Rectangle" or kind = "Label"
        themeNode(node, "color")
    else if kind = "Poster"
        if not node.HasField("tu")
            node.AddField("tu", "string", false)
            node.tu = node.uri
        end if
        base = node.tu
        backdrop = false
        for each name in ["guide-background.png", "header-gradient.png"]
            if Right(base, Len(name)) = name
                backdrop = true
                if m.themeUris.DoesExist(name) then node.uri = "pkg:/images/" + m.themeUris[name] else node.uri = base
            end if
        end for
        if backdrop
            if not node.HasField("bd")
                node.AddField("bd", "boolean", false)
                m.themeBackdrops.Push(node)
            end if
        else if colorHex(node.blendColor) <> "0xFFFFFFFF" or node.HasField("tb")
            themeNode(node, "blendColor")
        end if
    end if
    for each child in node.GetChildren(-1, 0)
        themeWalk(child)
    end for
end sub

' Colour fields read back as numbers (RGBA); this turns one into "0xRRGGBBAA".
function colorHex(value as Dynamic) as String
    if type(value) = "String" or type(value) = "roString" then return "0x" + UCase(Mid(value, 3))
    n = value
    digits = "0123456789ABCDEF"
    text = ""
    for i = 1 to 8
        text = Mid(digits, (n and 15) + 1, 1) + text
        n = (n >> 4) and &h0FFFFFFF
    end for
    return "0x" + text
end function

sub themeNode(node as Object, field as String)
    if not node.HasField("tb")
        node.AddField("tb", "string", false)
        node.tb = colorHex(node[field])
        themeRegister(node, field)
    end if
    node[field] = tc(node.tb)
end sub

' Channel Color tints the grey background and header; other themes show them as drawn.
sub themeBackdropTint()
    tint = "0xFFFFFFFF"
    if m.themeId = "channel" then tint = m.channelTint
    for each poster in m.themeBackdrops
        poster.blendColor = tint
    end for
end sub

' ---- Channel Color -------------------------------------------------------------
' The whole guide takes its colours from the selected channel's own colour (from
' Spelunkr's lineup), and fades to the next channel's as you move. Flipping fast
' only recolours once you settle, like the preview.

sub channelThemeFor(channel as Object)
    if m.themeId <> "channel" then return
    tint = spelunkrColor(channel.color)
    if tint = m.channelTint then return
    m.channelTintNext = tint
    if m.channelTintTimer = invalid then m.channelTintTimer = makeTimer(0.25, false, "applyChannelTint")
    m.channelTintTimer.Control = "stop"
    m.channelTintTimer.Control = "start"
end sub

sub applyChannelTint()
    if m.themeId <> "channel" or m.channelTintNext = invalid then return
    ' The big surfaces fade from where they are; small things switch at once.
    fades = []
    for each id in ["background", "header", "previewPanel", "previewPanelInfo", "listPanel", "guideHeader", "selectionBar"]
        node = m.top.FindNode(id)
        if node <> invalid
            field = "color"
            if node.Subtype() = "Poster" then field = "blendColor"
            fades.Push({id: id, field: field, from: colorHex(node[field])})
        end if
    end for
    m.channelTint = m.channelTintNext
    m.themeMap = channelPalette(m.channelTint)
    for each entry in m.themeNodes
        entry.node[entry.field] = tc(entry.node.tb)
    end for
    themeBackdropTint()
    if m.tintFade = invalid
        m.tintFade = CreateObject("roSGNode", "Animation")
        m.tintFade.Duration = 0.45
        m.tintFade.EaseFunction = "linear"
        m.top.AppendChild(m.tintFade)
    end if
    m.tintFade.Control = "stop"
    while m.tintFade.GetChildCount() > 0
        m.tintFade.RemoveChildIndex(0)
    end while
    for each fade in fades
        node = m.top.FindNode(fade.id)
        target = colorHex(node[fade.field])
        if target <> fade.from
            interp = m.tintFade.CreateChild("ColorFieldInterpolator")
            interp.Key = [0.0, 1.0]
            interp.KeyValue = [fade.from, target]
            interp.FieldToInterp = fade.id + "." + fade.field
            node[fade.field] = fade.from
        end if
    end for
    if m.tintFade.GetChildCount() > 0 then m.tintFade.Control = "start"
end sub

' A palette from one colour: dark shades for surfaces, the colour itself (lifted
' if it's too dark to glow) for what's lit, and a pale tint for headings. Text
' stays white or near-white, so every channel reads the same.
function channelPalette(tint as Dynamic) as Object
    if tint = invalid then tint = "0xD2640FFF"
    hex = UCase(Mid(tint, 3, 6))
    r = Val(Mid(hex, 1, 2), 16)
    g = Val(Mid(hex, 3, 2), 16)
    b = Val(Mid(hex, 5, 2), 16)
    light = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    accent = [r, g, b]
    if light < 0.45 then accent = mixRgb(accent, [255, 255, 255], 0.35)
    deep = mixRgb([r, g, b], [0, 0, 0], 0.86)
    deeper = mixRgb([r, g, b], [0, 0, 0], 0.91)
    mid = mixRgb([r, g, b], [0, 0, 0], 0.62)
    soft = mixRgb(accent, [255, 255, 255], 0.55)
    bright = mixRgb(accent, [255, 255, 255], 0.3)
    shaded = mixRgb(accent, [0, 0, 0], 0.3)
    bar = mixRgb(accent, [0, 0, 0], 0.4)
    accentLight = (0.299 * accent[0] + 0.587 * accent[1] + 0.114 * accent[2]) / 255.0
    onAccent = "FFFFFFFF"
    if accentLight > 0.55 then onAccent = "120A04FF"
    return {
        "1B2868FF": rgbHex(deep) + "E8", "0A1040FF": rgbHex(deeper) + "FF", "344A91FF": rgbHex(mid) + "FF", "A64310FF": rgbHex(bar) + "F0",
        "060B1EFF": "000000FF", "060B1ECC": "000000D8", "2A3580FF": rgbHex(mid) + "FF",
        "FFD740FF": rgbHex(bright) + "FF", "FFD740E6": rgbHex(bright) + "FF", "FFE22EFF": rgbHex(soft) + "FF", "00CCDDEE": rgbHex(soft) + "FF",
        "7788BB66": rgbHex(soft) + "44", "7788BB33": rgbHex(soft) + "20", "00000048": "00000060",
        "2B2FC4FF": rgbHex(mid) + "FF", "2226A0FF": rgbHex(mixRgb(mid, [0, 0, 0], 0.3)) + "FF", "D2640FFF": rgbHex(shaded) + "FF", "B0480AFF": rgbHex(mixRgb(shaded, [0, 0, 0], 0.35)) + "FF",
        "14153AFF": "000000FF", "3157A5FF": rgbHex(mid) + "FF", "1F2A6BFF": rgbHex(deep) + "FF", "99A3CCFF": rgbHex(soft) + "FF", "B9B0E8FF": rgbHex(soft) + "FF",
        "B8500EFF": rgbHex(shaded) + "FF", "E0700FFF": rgbHex(accent) + "FF", "4A50F0FF": rgbHex(mixRgb(mid, [255, 255, 255], 0.15)) + "FF", "FFF6A0FF": rgbHex(soft) + "FF",
        "07112BEE": rgbHex(deeper) + "EE", "07112BF4": rgbHex(deeper) + "FF", "07112BFF": rgbHex(deeper) + "FF", "27334FFF": rgbHex(mid) + "FF", "1A0B4BFF": rgbHex(deep) + "FF",
        "FFD74055": rgbHex(bright) + "66", "2B2FC5FF": rgbHex(mixRgb(mid, [0, 0, 0], 0.2)) + "FF", "0A1041FF": rgbHex(deeper) + "FF", "1B2869FF": rgbHex(deep) + "FF", "6A70FFFF": rgbHex(bright) + "FF", "FFFFFEFF": "120A04FF",
        "D2640EFF": rgbHex(accent) + "FF", "B0480BFF": rgbHex(shaded) + "FF", "E0700EFF": rgbHex(bright) + "FF", "FFE22FFF": onAccent
    }
end function

function mixRgb(color as Object, target as Object, amount as Float) as Object
    return [Int(color[0] + (target[0] - color[0]) * amount), Int(color[1] + (target[1] - color[1]) * amount), Int(color[2] + (target[2] - color[2]) * amount)]
end function

function rgbHex(color as Object) as String
    digits = "0123456789ABCDEF"
    text = ""
    for each value in color
        if value < 0 then value = 0
        if value > 255 then value = 255
        text = text + Mid(digits, Int(value / 16) + 1, 1) + Mid(digits, (value mod 16) + 1, 1)
    end for
    return text
end function

' Rounded frames over the guide's panels (Glass and Neon), made once.
sub themeFrames()
    if m.themeFrameNodes = invalid
        m.themeFrameNodes = []
        back = m.top.FindNode("guideBack")
        front = m.top.FindNode("guideFront")
        ' Preview, info and listings panels; each sits a little inside its old box.
        ' The listings frame goes under the CHANNEL and time row, so their text is
        ' drawn on top of it at full strength; a small gap separates top and bottom.
        specs = [
            {parent: back, after: "previewVideoFrame", x: 32, y: 82, w: 378, h: 268},
            {parent: front, after: "infoRightEdge", x: 418, y: 82, w: 830, h: 268},
            {parent: front, before: "guideHeader", x: 32, y: 360, w: 1216, h: 324}
        ]
        for each spec in specs
            frame = CreateObject("roSGNode", "Poster")
            frame.Translation = [spec.x - 10, spec.y - 10]
            frame.Width = spec.w + 20
            frame.Height = spec.h + 20
            frame.Visible = false
            index = 0
            for i = 0 to spec.parent.GetChildCount() - 1
                id = spec.parent.GetChild(i).id
                if spec.after <> invalid and id = spec.after then index = i + 1
                if spec.before <> invalid and id = spec.before then index = i
            end for
            spec.parent.InsertChild(frame, index)
            m.themeFrameNodes.Push(frame)
        end for
    end if
    for each frame in m.themeFrameNodes
        if m.themeId = "classic" or m.themeId = "channel"
            frame.Visible = false
        else
            frame.Uri = "pkg:/images/themes/" + m.themeId + "-panel.9.png"
            frame.Visible = true
        end if
    end for
end sub

function themeName(id as String) as String
    for each theme in themeList()
        if theme.id = id then return theme.name
    end for
    return "Classic"
end function
