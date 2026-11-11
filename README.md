<p align="center"><img src="assets/icon.png" alt="Spelunkr TV Guide icon" width="112"></p>
<h1 align="center">Spelunkr TV Guide</h1>
<p align="center"><strong>Unofficial Roku app for the Spelunkr live channel lineup</strong></p>
<p align="center">Live guide · Live preview · Channel directory · Version 1.6</p>

> **Unofficial app.** Spelunkr TV Guide for Roku is an independent, fan-made client. It is not made, endorsed or supported by [Spelunkr](https://spelunkr.tv/). Channel names, logos, descriptions and schedules belong to Spelunkr and its sources, and are read from Spelunkr's public guide data while the app runs.

Spelunkr TV Guide puts [Spelunkr](https://spelunkr.tv/)'s always-on retro channels on your TV in a printed-guide style lineup. Every channel runs on the wall clock, so tuning in joins the program where the broadcast is right now, station breaks included, just like on the website.

![Spelunkr TV Guide 1.6 splash screen](assets/splash.png)
<p align="center"><em>The 1.6 splash screen, as packaged in the Roku ZIP.</em></p>

## Download and install

| Package | What you get | Download |
| --- | --- | --- |
| **Roku ZIP** | The sideloadable app; upload this ZIP directly to your Roku | [spelunkr-tv-guide-v1.6-roku.zip](https://github.com/snuffy420/Spelunkr-TV-Guide/releases/download/v1.6/spelunkr-tv-guide-v1.6-roku.zip) |
| **Source 7z** | Editable BrightScript, artwork, build tools and documentation | [spelunkr-tv-guide-v1.6-source.7z](https://github.com/snuffy420/Spelunkr-TV-Guide/releases/download/v1.6/spelunkr-tv-guide-v1.6-source.7z) |

Checksums sit beside both downloads on the [release page](https://github.com/snuffy420/Spelunkr-TV-Guide/releases/tag/v1.6). The source archive is for development; the Roku installer needs the Roku ZIP.

### Install on Roku

1. Enable Developer Mode: press **Home** three times, **Up** twice, then **Right, Left, Right, Left, Right**. Follow the TV prompts, set an installer password, and note the Roku IP address.
2. From a computer on the same network, open `http://ROKU_IP` in your browser.
3. Sign in as `rokudev` using your installer password.
4. Select **Upload**, choose `spelunkr-tv-guide-v1.6-roku.zip`, then select **Install**.
5. Open **Spelunkr TV Guide**. Reinstalling replaces the existing sideloaded app.

See [Roku's developer setup](https://developer.roku.com/docs/developer-program/getting-started/developer-setup.md) for the official instructions.

## Explore Spelunkr TV Guide

### A guide that follows the clock

The guide shows three hours of listings for eight channels at a time, with the date and time in the header. Pause on a channel and its live preview tunes in behind animated static, with a `TUNING IN` timer while the stream loads. The info panel shows what is on now, how far into it the broadcast is, and what is up next. Press **OK** to watch full screen.

### Flip channels while you watch

In full screen, **Up** and **Down** change channels like a TV remote, without going back to the guide. The new channel opens once you stop flipping, so passing through several channels stays quick. A banner shows the channel and program, then fades.

### Channel directory

Press **Options (\*)** in the guide to open the directory: every channel in dial order with its description, tape and hour counts, and what is on it right now. NOW PLAYING follows the live schedule. Each card has **TUNE IN**, which plays the channel full screen, and **VIEW CHANNEL**, which takes you to it in the guide.

### The broadcast, as it airs

Programs, station breaks, bumper cards and vintage commercials start when they do on the website. When a slot ends, the next program takes over automatically in the preview and in full screen.

## Controls

| Screen | Remote controls |
| --- | --- |
| **Guide** | Up/Down channels; Left/Right jump eight channels; OK watch full screen; * directory |
| **Directory** | Arrows choose a card and button; OK select; REW/FF page; Back or * guide |
| **Watching** | Up/Down change channel; Left/Right 10 seconds; OK or Back return to the guide |
| **Load error** | * retries loading the lineup |

## Live data

The lineup, schedules and program details load from Spelunkr's public guide data each time the app opens. Video plays from Internet Archive. New channels on Spelunkr appear in the app once they are added to its channel list and logo set; see [Building](docs/BUILDING.md). The app does not host, record or modify video.

Playback depends on the program's current Internet Archive file. A stream downloads its index before the picture appears; the static and `TUNING IN` timer cover that wait, and `NO SIGNAL` means the stream failed after retries.

## Development and license

The source uses a fixed set of guide rows and directory cards, a single background worker for all listing downloads, and bundled pixel logos, so browsing stays responsive on low-end Roku models. [Build instructions](docs/BUILDING.md) cover packaging, the source archive and regenerating logos. [Release notes](CHANGELOG.md) describe each version.

Spelunkr TV Guide's application code is licensed under [GPL-3.0](LICENSE). Spelunkr's names, logos, channel data and the videos it schedules keep their own terms. See [THIRD_PARTY.md](THIRD_PARTY.md).

## Support Spelunkr TV Guide

<img src="assets/bitcoin.svg" width="24" height="24" alt="Bitcoin">

If Spelunkr TV Guide is useful to you, consider supporting its development with a Bitcoin donation. Donations are optional and appreciated.

**Bitcoin (BTC):**
`bc1qz8877p6vusc22qrctdj4h7w0uk2l9l9h8lwphy`

## Contact

Questions, feedback, a bug report or a custom build? Get in touch through the developer contact form.

<p align="center">
  <a href="https://snuffy420.github.io/zer0TV/docs/contact.html">
    <img src="assets/contact-button.svg" alt="Contact the developer" width="260">
  </a>
</p>
