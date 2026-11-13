# Roku certification checklist

Roku's Static Analysis flagged these on the Spelunkr TV Guide 1.6 upload (November 2026). They are fixed in 1.7; 1.9.3 keeps every fix. Every zer0TV build has the same code-level issues, so use this list for those apps too.

## Errors (block publishing)

| # | Static Analysis message | Fix in Spelunkr 1.7 | Where |
| --- | --- | --- | --- |
| 1 | Channels are required to support roInput events (5.2 Deep Linking) | `Main(args)` passes launch `contentId`/`mediaType` to the scene; an `roInput` on the main port forwards deep links that arrive while running. `contentId` is a channel id (`primetime`) or dial (`8`, `300`); the channel plays full screen. Keep `supports_input_launch=1`. | `source/main.brs`, `MainScene.brs` `onDeepLink` / `applyDeepLink` |
| 2 | Manifest needs `rsg_version=1.3` | `rsg_version=1.3`. **Also set the minimum firmware to 15.1.0 or later** in the Developer Dashboard when uploading; Static Analysis checks that too. | `manifest` |
| 3 | "AppLaunchComplete" beacon is missing (3.2) | `m.top.signalBeacon("AppLaunchComplete")` once, when the guide is usable, or when the lineup load error is showing. | `MainScene.brs` `signalLaunchComplete` |

## Warnings

| # | Static Analysis message | Fix in Spelunkr 1.7 |
| --- | --- | --- |
| 4 | `InitClientCertificates()` is deprecated | Removed. Public HTTPS only needs `SetCertificatesFile("common:/certs/ca-bundle.crt")`. Only use device attestation if a server actually requires it. |
| 5 | `mm_icon_focus_hd` must be 290×218 | New `images/icon_hd.png` (290×218) and `images/icon_fhd.png` (540×405). |
| 6–10 | `EnableLowGeneralMemoryEvent`, `EnableMemoryWarningEvent`, `GetChannelAvailableMemory`, `GetChannelMemoryLimit`, `GetMemoryLimitPercent` usage not found | In `Main`: `roAppMemoryMonitor` gets `EnableMemoryWarningEvent` and the three `Get…` calls; **`EnableLowGeneralMemoryEvent` goes on `roDeviceInfo`** (its events arrive as `roDeviceInfoEvent` with `generalMemoryLevel`). Calling it on `roAppMemoryMonitor` halts `Main` in the debugger, so the guide draws but nothing loads (seen in the first 1.7 test on Roku OS 16.0.4). All of these calls sit in `try`/`catch`. On a warning the scene releases the preview stream unless the viewer is watching full screen. |
| 11 | Fire `AppDialogInitiate` / `AppDialogComplete` if a dialog shows before the home page | Not needed: Spelunkr shows no dialog before the guide. An app that shows a login, EULA, profile picker or other dialog before its home screen must fire both beacons around it. |

## Device tests (Channel Store upload of 1.7.1)

| Test | Result | Cause and fix |
| --- | --- | --- |
| Channel Content Play Performance (3.6) | Fail | The test plays the registered deep link and Roku times the video start. Measured on a Roku TV: `primetime` took **14.1 s** (`VODStartComplete`), `homeroom` **5.5 s**. Before the first frame the player downloads the MP4 index (`moov`), and PRIMETIME's 3–5 hour tapes carry 2.8–29 MB indexes (12 MB average) against HOMEROOM's 0.2–1.2 MB. **Register `homeroom` (mediaType Live) as the deep-link parameter**, not `primetime`. HAPPY TREES (max 2.3 MB) is a good second choice. |
| Screensaver Policy (4.5) | Error | Full screen ignored Pause, so a deep-linked stream never stopped and the screensaver could not start. 1.7.2 adds Play/Pause in full screen; 1.7.1 added the idle timeout on the guide. |

Measure video start yourself from the debug console (`telnet ROKU_IP 8085`) while sending a deep link; look for `VODStartComplete ---> Duration(…)`.

## Roku player limit on some tapes

Found while testing 1.8 on a Roku TV (Roku OS 16.0.4). Seven SATURDAY MORNING tapes (YouCut edits, CN Saturday mornings 2009-2011) use a video timescale of 1,000,000 ticks per second, so their 4-5 hour lengths need a 64-bit duration. The Roku player keeps only the lower 32 bits and treats each tape as much shorter: it cannot open the file, or jump in it, past that point (36:26 into the Feb. '11 tape, 50:20 into Dec. '10 Vol. 2; both matched the prediction to the second). Playing straight through the point works. The errors are `-3 sample number too large` and `-5 malformed data / demux get sample error`.

Since 1.9.2 the app catches those errors, works the limit out from the tape's length, reopens the tape a few seconds before it and marks playback **OUT OF SYNC**. OK in full screen offers what happens next (back to live at the next program, finish this program, or stay delayed through the lineup). Normal tapes are not affected; their timescales (12,000-60,000) leave room for 20+ hours.

## Testing deep links

With the dev app sideloaded, from a computer on the same network:

```bash
curl -d "" "http://ROKU_IP:8060/launch/dev?contentId=primetime&mediaType=live"
```

```bash
curl -d "" "http://ROKU_IP:8060/input?contentId=300&mediaType=live"
```

The first launches straight into PRIMETIME full screen; the second, sent while the app is open, switches to channel 300. Roku's Deep Linking Tester tool does the same checks.

## Carry-over to other apps (scan of November 11, 2026)

| App build | rsg 1.3 | roInput | AppLaunchComplete | InitClientCertificates | Memory monitor | Focus icons |
| --- | --- | --- | --- | --- | --- | --- |
| zer0TV 1.5.5 public (`zer0TV-v1.5.5-release/source`) | needs fix | needs fix | needs fix | remove | needs fix | OK |
| zer0TV private lab (`zer0TV-private-lab/source`) | needs fix | needs fix | needs fix | remove | needs fix | OK |
| zer0TV 1.5 / 1.0 older builds and test copies | needs fix | needs fix | needs fix | remove | needs fix | OK |

All of them already have `supports_input_launch=1`, but none handles `roInput` or the launch `contentId`, so Roku's deep-link test would still fail. For zer0TV, choose what a `contentId` means (for example a channel or movie id) before adding deep linking.
