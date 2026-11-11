# Changelog

## 1.7.2 - November 11, 2026

- Add Play/Pause while watching full screen. A paused picture lets the Roku screensaver start (screensaver policy, 4.5). Resume rejoins the live broadcast; if the program changed while paused, the new one opens. Changing channel or leaving full screen clears the pause.
- Show PAUSED on the playback banner and add PLAY PAUSE to the full-screen hints.
- Show 1.7.2 on the splash screen.

## 1.7.1 - November 11, 2026

- Screensaver policy: after 5 minutes with no remote input on the guide, the live preview stops and shows "PREVIEW PAUSED · PRESS ANY BUTTON", so the Roku screensaver can start. The first button press only wakes the preview. Full-screen playback and the directory are unaffected.
- Show 1.7.1 on the splash screen; packages are named `v1.7.1`.

## 1.7 - November 11, 2026

Roku Channel Store certification fixes.

- Add deep linking. A launch or in-app deep link with `contentId` set to a channel id (`primetime`) or dial number (`8`, `300`) plays that channel full screen. Links that arrive before the lineup loads wait for it.
- Declare `rsg_version=1.3` in the manifest, as Roku requires from October 2026.
- Fire the `AppLaunchComplete` beacon once the guide is ready, or when it shows a lineup load error.
- Add memory monitoring: app memory warnings and low general memory events. On a warning the guide releases its preview stream unless you are watching full screen.
- Remove the deprecated `InitClientCertificates()` call; HTTPS uses the standard certificate bundle.
- Add home-screen focus icons at Roku's required sizes, 290×218 and 540×405.
- Show 1.7 on the splash screen.
- Add `docs/ROKU_CERTIFICATION.md`, a checklist of the Static Analysis findings and how each was fixed.

## 1.6 - November 10, 2026

- Add channel up/down while watching full screen. **Up** goes to the next higher channel and **Down** to the previous one, wrapping at either end, without going back to the guide. The new stream opens once flipping settles, so passing through several channels stays quick.
- Show "Tuning in..." on the playback banner while a new channel's listings load.
- Add `UP / DOWN  CHANNEL` to the full-screen hints; OK or Back now returns to the guide.
- Put the `*` on the DIRECTORY button itself instead of repeating DIRECTORY in the footer hints.
- Add `tools/release.py` to build the source 7z, with SHA-256 checksums for both downloads.

## 1.5

- Add the channel directory, opened with **Options (\*)** or the DIRECTORY button in the guide footer. Cards show each channel's dial, logo, name, REWIND tag, description, and tape and hour counts, read live from the lineup.
- Add a live NOW PLAYING line to every directory card. It follows the schedule as programs change; during a station break it names the program coming up.
- Make each directory card selectable: **TUNE IN** plays the channel full screen (waiting for its listings if needed), and **VIEW CHANNEL** selects it in the guide.
- Directory controls: arrows choose a card and button, REW/FF page, Back or * return to the guide. The preview stops while the directory is open.
- Remove the channel description from the guide's info panel; the channel icon and name stay.

## 1.3

- Add Orange Soda (34) and Waku Waku (300) with their logos.
- Widen the dial column so three-digit channels (100s–600s) show in full.
- Widen the name column so full channel names show, including COMPUTER CHRONICLES.
- Move the listings grid flush with the panel's right edge, using the empty space on the right.
- Show today's date next to the clock (for example `11/10   5:39 PM`).
- Center the CHANNEL heading over the dial and name columns.
- Show the version on the splash screen.

## 1.0

- First Roku release: Spelunkr's live channel lineup and listings in a classic TV-guide layout, three hours at a time.
- Wall-clock broadcasts: tuning in joins each program where it has reached, not at its beginning.
- Live preview with the channel-switch static effect, a `TUNING IN` timer and buffer percentage, and `NO SIGNAL` when a stream fails.
- Now and next program details, with descriptions and an elapsed-time display that follows the clock.
- Full-screen playback with an information banner and 10-second seeking.
- Automatic hand-off to the next program when a slot ends, in the preview and full screen.
- The website's station breaks: bumper and up-next cards, and vintage commercials on channels that run them.
- Faster stream starts: direct archive.org server lookups, live-point prediction from the file index, and drift correction back to the broadcast.
- Purple and orange guide styling drawn from the Spelunkr guide.
