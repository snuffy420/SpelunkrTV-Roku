# Changelog

## 1.9.2 - November 12, 2026

### A guide that moves with the clock

- The listings scroll with time: a yellow now line stays half an hour into the three-hour window while the listings and half-hour time headings creep left, one whole pixel at a time (about every 12 seconds), so text stays sharp. A small yellow marker shows the now line in the time header.
- REW / FF in the guide look back or ahead half an hour per press, with a short glide. The header shows the time range being viewed; after 10 seconds without a time key the guide glides back to now. Scrolling channels while looking ahead keeps the time view.
- A program that started before the window shows its title from the window's left edge, after a small arrow, like the old cable guide channels.
- The now line splits every row: everything that has aired, left of it, is shaded darker, and everything still to come is bright. All programs share one color, so nothing to the right of the line looks dimmed.
- Time labels show only when they fit whole; the partial columns at the window's edges keep their divider and listings.
- The guide is one continuous list that wraps round, with no pages and no empty rows: 02 sits right under 600. Up/Down past the top or bottom row scroll the list one channel; Left/Right move it eight channels.

### Scan

- Play/Pause in the guide starts Scan: the listings roll up one channel every 4 seconds through the whole lineup, and every 45 seconds the channel at the top is featured in the preview and info panel, like the SCAN button on an old TV. The SCAN button in the footer turns orange and shows pause while it is on, and goes back to blue with play when it stops.
- Up/Down and Left/Right scroll by hand and pause the roll for 10 seconds; OK watches the featured channel; Play/Pause again or Back ends Scan. Scan stops after 4 hours without a button press.

### Easier to read

- Back-to-back short shows (under about 10 minutes) draw as one cell with the first title, the number of shows and their total time. RUBBER HOSE (400) no longer shows a row of empty boxes.
- Smaller program titles and running times, so more of each title fits.
- Info panel: NOW PLAYING sits beside the channel name; the description gets up to four lines and UP NEXT two.
- Directory and info panel text is measured and sized to fit its box, so long channel descriptions and NOW PLAYING titles show in full instead of ending in "...".
- The button hints along the bottom of the guide, directory, full screen and playback options are remote-button icons styled after the Roku remote (purple direction pad and OK, dark round rewind, play/pause, fast forward and back), each with one word. Status messages (loading, time view, roll paused) sit in the header, left of the clock.

### Playback

- Faster stream starts: the archive.org server and folder lookups run together, the preview opens sooner after you stop on a channel, the static clears faster, a failed direct link retries through archive.org after 1 second, and learned open times are kept between launches.
- Faster guide loading: the rows on screen load first; finished listings and program descriptions are kept between launches, so reopening the app within about an hour and a half needs no download or rebuild; downloads overlap with building the previous channel. Channels with commercials (up to 1,555 of them) build far faster: the commercial ranking and era lists are worked out once per commercial set and shared between channels, with the comparisons inlined.
- Tapes with very large indexes (12-38 MB on some TOONERTIA tapes) no longer restart over and over: a stream counts as stuck only when its buffer stops filling.
- Tapes the Roku player can't join live: a few SATURDAY MORNING tapes (YouCut edits with a microsecond timescale) can't be opened or jumped into past a point the Roku player computes from their length cut to 32 bits (36:26 into one 4-hour tape). Instead of NO SIGNAL, the tape plays from the furthest point it can reach, marked OUT OF SYNC on the playback banner.
- OK while watching full screen opens playback options: start the program from the beginning, go back to live, and choose what happens next: switch to the live program at its start, finish this program and then rejoin live, or stay delayed and keep playing the channel's lineup in order (station breaks included), like a DVR. Pausing while out of sync adds to the delay. Back returns to the guide; * is left to the Roku TV's own settings menu.
- Hide the Roku video player's built-in on-screen display (its clock, trick-play bar and loading bars). It is laid out for full screen even in the guide, and while a stream loaded its clock peeked out from behind the info panel at the right edge.
- The full-screen banner shows the channel's icon beside its number and name.
- Show 1.9.2 on the splash screen.

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
