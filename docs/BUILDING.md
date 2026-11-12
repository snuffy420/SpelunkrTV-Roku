# Building Spelunkr TV Guide 1.9.2

## Roku ZIP

Python 3.12 or newer is enough to package the app:

```bash
python tools/package.py
```

Output: `releases/spelunkr-tv-guide-v1.9.2-roku.zip` and its SHA-256 sidecar. The ZIP holds `manifest`, `source`, `components` and `images` at its root; SVG/GIF sources, docs and tools are left out. The version comes from `manifest`.

## Source archive

Install 7-Zip (`7z` on PATH, or the standard Windows install), then run:

```bash
python tools/release.py
```

This builds the Roku ZIP and a real 7z source archive, tests both, and writes checksums. `releases`, build output, dependency folders and Python caches are excluded from the source archive.

## Logos and static

`images/logos/` and `images/tv-static-sheet.png` are generated. Regenerate them when channels or logos change upstream (needs Pillow):

```bash
python tools/build_assets.py
```

The guide only lists channels named in `directoryIds` in `components/GuideTask.brs`, which keeps it in step with the public directory; the upstream lineup also carries internal test feeds. To add a new Spelunkr channel, add its id there, run `build_assets.py`, then package.

## Hint icons

`images/hints/` holds the remote-button icons shown in the button hints, drawn by `tools/build_hint_icons.py` (needs Pillow). They are styled after the Roku remote; run the script again after changing a glyph or colour.

## Splash screen

`images/splash-art.svg` holds the splash background and text; `images/splash_hd.png` (1280×720) and `images/splash_fhd.png` (1920×1080) are the packaged images, with the Spelunkr mark above the title.

## Broadcast timing

`components/BroadcastEngine.brs` follows the website's scheduling engine (manifest engine version 5), so programs and breaks start when they do on the site. If that engine version changes, or the timing fails for a channel, the channel falls back to a plain schedule without breaks until the code is updated. Bumper music is not played.

A stream has to download and process its index (the MP4 `moov`, 0.5–12 MB on these files) before it shows a picture. To keep that wait short and the picture on time:

- The worker looks up which archive.org server holds each upcoming file, so the player skips the `archive.org/download` redirect. If a direct link fails, that file goes back to the normal link.
- Each stream asks for the point the broadcast will have reached once its index has loaded, estimated from the index size and learned from previous opens on the TV.
- The static clears as soon as the video position moves, even if the Roku still reports `buffering`.
- If the picture drifts more than 10 seconds from the broadcast, it jumps back to the live point.
- A stream counts as stuck only when its buffer stops filling, so tapes with 12-38 MB indexes are not restarted mid-load.
- The video player's own on-screen display (clock, trick-play bar) is hidden; it is laid out for full screen even in the guide preview.

Some tapes cannot be opened past a point the Roku player computes from their length cut to 32 bits; see `docs/ROKU_CERTIFICATION.md`. The app then plays them from the furthest point it can reach, marked OUT OF SYNC.

## Listings speed

- The worker builds the selected channel and the rows on screen first, then the rest outward from them.
- Built listings are saved in `cachefs:` with the schedule version and window they cover, and program descriptions by their versioned file name. A relaunch within about an hour and a half shows them at once; each cached channel is then rebuilt from live data in the background and saved again.
- The worker sends results to the scene in batches at least 100 ms apart. Setting a field many times in a row from a task thread delivers only the last value to the render thread.
- Commercial ranking and era lists are worked out once per commercial set and shared between channels (five channels share one set of 1,555); the comparisons are inlined. This is the costliest part of replaying a channel's station breaks.
- Each pass of the worker loop catches and logs its own errors, so one bad request cannot end listing updates.

## Performance rules

- The guide and directory use fixed sets of nodes that are rewritten, never created per page or removed. The guide has nine rows (eight on screen, one below for scrolling and Scan) that are reused as the list moves, so only one row is redrawn per step.
- The listings sit on one strip that slides under the time window; moving it changes one translation, not every cell. It moves in whole pixels so text stays sharp.
- Logos are bundled PNGs, not rectangles drawn from pixel data.
- Nodes are looked up once in `init()`. `FindNode` walks the tree, so do not call it per key press or per tick.
- One worker task handles all listing downloads. Do not start a task per page.
- All times are whole epoch seconds. Upstream millisecond values do not fit in a 32-bit Integer.

## Checks

The BrighterScript compiler catches syntax and reserved-word errors off-device:

```bash
npx -p brighterscript bsc --rootDir . --files "manifest" "source/**/*" "components/**/*" --createPackage false
```

Remote focus, video decoding and layout still need a Roku device.

## Shared README style

The README follows the same layout as the developer's other apps: centered icon/title/tagline, download table, install, features/controls, development/license, support and contact. `assets/contact-button.svg` and `assets/bitcoin.svg` share that style.
