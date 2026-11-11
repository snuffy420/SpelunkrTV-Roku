sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("MainScene")
    screen.Show()

    ' Deep links while the app is running (certification 5.2). Launch-time deep
    ' links arrive in args.
    input = CreateObject("roInput")
    input.SetMessagePort(port)

    ' Memory monitoring (certification monitoring checks). On a low-memory
    ' warning the scene releases the preview stream when it is not on screen.
    ' EnableLowGeneralMemoryEvent lives on roDeviceInfo, not roAppMemoryMonitor.
    ' Both are wrapped so a missing method on some Roku OS can never halt Main.
    memory = CreateObject("roAppMemoryMonitor")
    if memory <> invalid
        try
            memory.SetMessagePort(port)
            memory.EnableMemoryWarningEvent(true)
            print "Memory limit "; memory.GetChannelMemoryLimit(); " KB, available "; memory.GetChannelAvailableMemory(); " KB, used "; memory.GetMemoryLimitPercent(); "%"
        catch problem
            print "Memory monitor unavailable: "; problem.message
        end try
    end if
    device = CreateObject("roDeviceInfo")
    try
        device.SetMessagePort(port)
        device.EnableLowGeneralMemoryEvent(true)
    catch problem
        print "Low general memory event unavailable: "; problem.message
    end try

    sendDeepLink(scene, args)

    while true
        msg = Wait(0, port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        else if msgType = "roInputEvent"
            if msg.IsInput() then sendDeepLink(scene, msg.GetInfo())
        else if msgType = "roAppMemoryNotificationEvent" or msgType = "roAppMemoryMonitorEvent"
            print "App memory warning: "; FormatJson(msg.GetInfo())
            scene.lowMemory = true
        else if msgType = "roDeviceInfoEvent"
            info = msg.GetInfo()
            if type(info) = "roAssociativeArray" and info.generalMemoryLevel <> invalid
                print "General memory level: "; info.generalMemoryLevel
                if info.generalMemoryLevel <> "normal" then scene.lowMemory = true
            end if
        end if
    end while
end sub

' Passes a deep link (contentId = channel id such as "primetime", or a dial
' number such as "8" / "08") to the scene, which tunes to it full screen.
sub sendDeepLink(scene as Object, args as Dynamic)
    if type(args) <> "roAssociativeArray" then return
    contentId = args.contentId
    if contentId = invalid then return
    if type(contentId) <> "String" and type(contentId) <> "roString" then contentId = contentId.ToStr()
    if contentId = "" then return
    mediaType = ""
    if args.mediaType <> invalid then mediaType = args.mediaType
    scene.deepLink = {contentId: contentId, mediaType: mediaType}
end sub
