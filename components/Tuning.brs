' ---- Channel number and the tuning card ------------------------------------------
' Like an old TV: flipping channels puts a big outlined "CH 08" over the picture
' (in the preview and, drawn at its own larger size, in full screen). While a
' tape loads, the preview shows a STAND BY card with a progress bar: the app's
' own estimate of the open time (learned on this TV), then Roku's buffering.

sub initTuning()
    m.osdSmall = buildOsd(m.top.FindNode("osdSmall"), 46, 3)
    m.osdLarge = buildOsd(m.top.FindNode("osdLarge"), 96, 5)
    m.osdTimer = makeTimer(2.5, false, "onOsdTimer")
    m.tuneCard = m.top.FindNode("tuneCard")
    m.tuneTitle = m.top.FindNode("tuneTitle")
    m.tuneTitleShadow = m.top.FindNode("tuneTitleShadow")
    m.tuneLine = m.top.FindNode("tuneLine")
    m.tuneNote = m.top.FindNode("tuneNote")
    m.tuneTrack = m.top.FindNode("tuneTrack")
    m.tuneFill = m.top.FindNode("tuneFill")
    m.tuneFrame = 0
    m.tuneTimer = makeTimer(0.25, true, "onTuneTimer")
end sub

' Chunky white digits with a black outline: eight black copies around the text
' and a drop shadow, then the white text on top. Drawn at the size it shows at,
' never scaled, so it stays crisp.
function buildOsd(group as Object, size as Integer, edge as Integer) as Object
    labels = []
    offsets = [[edge + 2, edge + 3], [-edge, 0], [edge, 0], [0, -edge], [0, edge], [-edge, -edge], [edge, -edge], [-edge, edge], [edge, edge], [0, 0]]
    for i = 0 to offsets.Count() - 1
        label = group.CreateChild("Label")
        ' A built-in font takes its size this way (a new Font node would ignore it).
        label.Font = "font:LargeBoldSystemFont"
        label.Font.Size = size
        label.Translation = offsets[i]
        if i = offsets.Count() - 1
            label.Color = "0xFFFFFFFF"
        else if i = 0
            label.Color = "0x01010180"
        else
            label.Color = "0x010101FF"
        end if
        labels.Push(label)
    end for
    return {group: group, labels: labels}
end function

' Called whenever the selected channel changes (flipping, the guide cursor, Scan).
sub showChannelOsd(channel as Object)
    if channel = invalid then return
    text = "CH " + channel.dial
    for each osd in [m.osdSmall, m.osdLarge]
        for each label in osd.labels
            label.Text = text
        end for
    end for
    m.osdLarge.group.Visible = m.fullscreen
    m.osdSmall.group.Visible = not m.fullscreen
    m.osdTimer.Control = "stop"
    m.osdTimer.Control = "start"
end sub

' The number stays while the static is up and a moment after the picture appears.
sub onOsdTimer()
    if m.previewStatic.Visible and not m.staticFading
        m.osdTimer.Control = "start"
        return
    end if
    hideChannelOsd()
end sub

sub hideChannelOsd()
    m.osdSmall.group.Visible = false
    m.osdLarge.group.Visible = false
end sub

' Entering or leaving full screen: the number moves to the matching size.
sub layoutChannelOsd()
    if m.osdSmall.group.Visible or m.osdLarge.group.Visible
        m.osdLarge.group.Visible = m.fullscreen
        m.osdSmall.group.Visible = not m.fullscreen
    end if
end sub

' The STAND BY card in the preview (guide only; full screen has its banner).
sub showTuneCard(notice as String)
    if notice <> ""
        m.tuneTitle.Text = notice
        m.tuneTitleShadow.Text = notice
        m.tuneLine.Text = ""
        m.tuneNote.Text = ""
        m.tuneTrack.Visible = false
        m.tuneFill.Visible = false
    else
        m.tuneTitle.Text = "STAND BY"
        m.tuneTitleShadow.Text = "STAND BY"
        m.tuneTrack.Visible = true
        m.tuneFill.Visible = true
        renderTuneProgress()
    end if
    if not m.tuneCard.Visible
        m.tuneCard.Visible = true
        m.tuneTimer.Control = "start"
    end if
end sub

sub hideTuneCard()
    if not m.tuneCard.Visible then return
    m.tuneCard.Visible = false
    m.tuneTimer.Control = "stop"
end sub

sub onTuneTimer()
    if not m.tuneCard.Visible then return
    if m.tuneTitle.Text = "STAND BY" then renderTuneProgress()
end sub

sub renderTuneProgress()
    m.tuneFrame = (m.tuneFrame + 1) mod 16
    dots = Left("...", Int(m.tuneFrame / 4) mod 4)
    m.tuneLine.Text = "TUNING IN" + dots
    fraction = 0.0
    seconds = 0
    if m.previewStartedAt > 0 and m.previewHasStream
        elapsed = m.openTimer.TotalMilliseconds() / 1000.0
        seconds = Int(elapsed)
        expected = predictOpenSeconds(m.openMoov)
        ' The estimate rises steadily but never claims to be done; Roku's own
        ' buffering figure takes over once it is further along.
        fraction = elapsed / expected
        if fraction > 0.9 then fraction = 0.9 + (fraction - 0.9) * 0.05
        if fraction > 0.95 then fraction = 0.95
        status = m.previewVideo.bufferingStatus
        if type(status) = "roAssociativeArray"
            if status.percentage <> invalid
                if status.percentage / 100.0 > fraction then fraction = status.percentage / 100.0
            end if
        end if
    end if
    if fraction < 0.02 then fraction = 0.02
    if fraction > 1 then fraction = 1
    m.tuneFill.Width = Int(m.tuneTrack.Width * fraction)
    ' The seconds ride on the TUNING IN line; the note below stays short and
    ' shrinks to fit rather than trail off.
    if seconds > 0 then m.tuneLine.Text = "TUNING IN" + dots + "  " + seconds.ToStr() + "s"
    note = "LONG TAPES CAN TAKE A MINUTE"
    if m.tuneNote.Text <> note then fitLabel(m.tuneNote, note, "font:SmallestSystemFont", [17, 16, 15, 14, 13], 302, 40)
end sub
