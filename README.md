<p align="center"><img src="assets/icon.png" alt="Spelunkr TV Guide icon" width="112"></p>
<h1 align="center">Spelunkr TV Guide (Unofficial)</h1>
<p align="center"><strong>Unofficial Roku app for the Spelunkr live channel lineup</strong></p>
<p align="center">Scrolling live guide · Scan · Schedules &amp; reminders · Themes · Channel directory · Version 1.9.8</p>
<p align="center"><strong>Now on the <a href="https://channelstore.roku.com/details/d0f119c3a7c09889197e96b29aa2ed65:4c8d28d1aa95bcad149caffdb9c9bada/unofficial-spelunkrtv-guide">Roku Channel Store</a>: install it like any other Roku app, no developer mode needed.</strong></p>

> **Unofficial app.** Spelunkr TV Guide for Roku is an independent, fan-made client. It is not made, endorsed or supported by [Spelunkr](https://spelunkr.tv/). Channel names, logos, descriptions and schedules belong to Spelunkr and its sources, and are read from Spelunkr's public guide data while the app runs.

Spelunkr TV Guide puts [Spelunkr](https://spelunkr.tv/)'s always-on retro channels on your TV in a printed-guide style lineup. Every channel runs on the wall clock, so tuning in joins the program where the broadcast is right now, station breaks included, just like on the website.

![Spelunkr TV Guide 1.9.8 splash screen](assets/splash.png)
<p align="center"><em>The 1.9.8 splash screen, as packaged in the Roku ZIP.</em></p>

## Download and install

### From the Roku Channel Store

The easiest way: install **Spelunkr TV Guide (Unofficial)** from the Roku Channel Store, like any other Roku app. There's no developer mode or computer involved, and Roku keeps it up to date for you. You can also find it by searching the Channel Store on your Roku for "Spelunkr". The Roku store may be a version behind Github as it takes a day to publish a new update to the Roku store.

**[Get Spelunkr TV Guide on the Roku Channel Store](https://channelstore.roku.com/details/d0f119c3a7c09889197e96b29aa2ed65:4c8d28d1aa95bcad149caffdb9c9bada/unofficial-spelunkrtv-guide)**

### Sideload the latest build

Sideloading is for trying a build before it reaches the Channel Store, or for development. It needs Developer Mode on your Roku.

| Package | What you get | Download |
| --- | --- | --- |
| **Roku ZIP** | The sideloadable app; upload this ZIP directly to your Roku | [spelunkr-tv-guide-v1.9.8-roku.zip](https://github.com/snuffy420/SpelunkrTV-Roku/releases/download/v1.9.8/spelunkr-tv-guide-v1.9.8-roku.zip) |
| **Source 7z** | Editable BrightScript, artwork, build tools and documentation | [spelunkr-tv-guide-v1.9.8-source.7z](https://github.com/snuffy420/SpelunkrTV-Roku/releases/download/v1.9.8/spelunkr-tv-guide-v1.9.8-source.7z) |

Checksums sit beside both downloads on the [release page](https://github.com/snuffy420/SpelunkrTV-Roku/releases/tag/v1.9.8). The source archive is for development; the Roku installer needs the Roku ZIP.

### Sideload on Roku

1. Enable Developer Mode: press **Home** three times, **Up** twice, then **Right, Left, Right, Left, Right**. Follow the TV prompts, set an installer password, and note the Roku IP address.
2. From a computer on the same network, open `http://ROKU_IP` in your browser.
3. Sign in as `rokudev` using your installer password.
4. Select **Upload**, choose `spelunkr-tv-guide-v1.9.8-roku.zip`, then select **Install**.
5. Open **Spelunkr TV Guide (Unofficial)**. Reinstalling replaces the existing sideloaded app. A sideloaded copy and the Channel Store copy are separate apps.

See [Roku's developer setup](https://developer.roku.com/docs/developer-program/getting-started/developer-setup.md) for the official instructions.

## Explore Spelunkr TV Guide

### A guide that moves with the clock

The guide shows three hours of listings for eight channels at a time, with the date and time in the header. A yellow line marks right now, half an hour into the window, and the listings creep left past it as the broadcast moves on. Programs that started earlier show their title at the left edge after a small arrow, like the old cable guide channels, and everything that has already aired, left of the line, is shaded a little darker.

The lineup is one continuous list: scroll past the last channel and the first comes round again, with no empty rows. Press **REW** or **FF** to look back or ahead half an hour at a time; the guide glides back to now on its own.

Pause on a channel and its 4:3 live preview tunes in behind animated static, with the channel number shown big like an old TV and a **STAND BY** card whose bar shows how far the tape has loaded. The info panel shows what is on now, how far into it the broadcast is, and what is up next. Press **OK** to watch full screen. The hints along the bottom show the remote buttons to press, and a gold star on a logo marks a favorite channel.

![The guide: live preview, info panel, the yellow now line and the listings](assets/screenshots/guide.jpg)

### Scan

Press **Play/Pause** in the guide and the listings roll up through the whole lineup on their own, one channel every few seconds. Every 45 seconds the channel at the top takes over the preview and info panel, like the SCAN button on an old TV. The **SCAN** button in the footer turns orange and shows pause while it runs. Scroll to take over for a moment, press **OK** to watch, or press **Play/Pause** or **Back** to stop.

![Scan rolling through the lineup, with the SCAN button lit](assets/screenshots/scan.jpg)

### Flip channels while you watch

In full screen, **Up** and **Down** change channels like a TV remote, without going back to the guide. The channel number appears big over the static, and the new channel opens once you stop flipping, so passing through several channels stays quick. A banner shows the channel's icon, number, program and position, and what is on next, then fades.

### Quick channel list

Press **Replay** while watching full screen for a slim list of every channel, its logo and what is on it now. The picture keeps playing while you scroll; **OK** switches to the highlighted channel and **Back** closes the list with nothing changed. **Left** and **Right** switch between all channels and your favorites.

### Playback options

Press **OK** while watching to open playback options. While you are live, you can start the program from the beginning or go back to the guide.

![Playback options while watching live](assets/screenshots/playback-options.jpg)

### Subtitles

Spelunkr publishes English subtitles for some tapes, today mostly the Japanese channels WAKU WAKU, ROCKET PUNCH, OVATV and HENSHIN. When the program you are watching has them, a **CC** tag shows on the banner and the info panel, and **OK → Subtitles** (or Options) turns them on or off. They start on, and the app remembers your choice. Many are machine translations, and some of those tapes already have subtitles in the picture. New subtitles Spelunkr adds appear without an app update.

### Out of sync

Starting a program over puts you behind the website's schedule. The banner then says **OUT OF SYNC** and how far behind you are, and pausing simply adds to the delay, like a DVR.

![The full-screen banner while out of sync](assets/screenshots/out-of-sync-banner.jpg)

Press **OK** again for more choices: go back to live, or decide what happens when the program ends:

- **At the next live program, switch to it** and be back in sync.
- **Finish this program, then rejoin live.**
- **Stay delayed** and keep watching the channel in order, station breaks and commercials included.

![Playback options while out of sync](assets/screenshots/out-of-sync-options.jpg)

The same screen appears on its own for a few SATURDAY MORNING tapes the Roku player cannot join live past a point partway in (see [Live data](#live-data)). The tape then plays from the furthest point it can reach.

### Channel directory

Press **Options (\*)** in the guide to open the directory: every channel in dial order with its description, tape and hour counts, and what is on it right now. NOW PLAYING follows the live schedule. Each card has **TUNE IN**, which plays the channel full screen, **VIEW CHANNEL**, which takes you to it in the guide, and **SCHEDULE**.

![The channel directory](assets/screenshots/directory.jpg)

### Schedules and reminders

**SCHEDULE** shows a channel's next 24 hours in your time, laid out like the website's schedule pages: a band for each part of the day, then each program with its time, length, year and description. **OK** on **REMIND ME** sets a reminder, and while the app is open a card pops up 15 minutes before the program starts: **OK** tunes in, **Back** dismisses it. The website's Discord reminders aren't needed for this.

![A channel's 24-hour schedule with REMIND ME buttons](assets/screenshots/schedule.jpg)

### Options, themes and favorites

Press **Replay** in the guide (the **OPTIONS** button) for:

- **Theme:** Classic, Glass (frosted 3D panels in Spelunkr's colours), Neon, Spelunkr Neon (orange and blue glow) or Channel Color, which takes each channel's own colour and fades to the next as you move.
- **Favorite:** star the channel you're on.
- **Weather in the header:** pick your country and enter a ZIP code, postcode or town (a number pad, or ABC for a full keyboard) for the current temperature and conditions, refreshed every 30 minutes. TURN OFF keeps the header as it is.
- **Settings:** start on your last channel, first favorite or first channel; a 12- or 24-hour clock; °F or °C; the guide preview with sound, muted or off; Scan speed; subtitles; and how long before the screensaver.
- **Reminders**, **What's new** and **About Spelunkr**.

![Choosing a theme](assets/screenshots/themes.jpg)

![The guide in the Glass theme](assets/screenshots/theme-glass.jpg)

### The broadcast, as it airs

Programs, station breaks, bumper cards and vintage commercials start when they do on the website. When a slot ends, the next program takes over automatically in the preview and in full screen.

## Controls

| Screen | Remote controls |
| --- | --- |
| **Guide** | Up/Down channels; Left/Right jump eight channels; REW/FF look back or ahead in time; OK watch full screen; Play/Pause Scan; * directory; Replay options |
| **Scan** | Any arrow stops Scan on the page you're looking at, cursor on the top channel; OK watches the highlighted channel; Play/Pause or Back stop Scan |
| **Directory** | Arrows choose a card and button (TUNE IN, VIEW CHANNEL, SCHEDULE); OK select; REW/FF page; Back or * guide |
| **Schedule** | Up/Down programs; REW/FF four at a time; OK REMIND ME (or TUNE IN on what is on now); Back closes |
| **Options** | Up/Down choose; OK change or open; Back closes |
| **Watching** | Up/Down change channel; Replay quick channel list; Play/Pause pause; Left/Right 10 seconds; OK playback options; Back guide |
| **Quick channel list** | Up/Down scroll; Left/Right all channels or favorites; OK watch; Back or Replay close |
| **Reminder card** | OK tune in; Back dismiss |
| **Load error** | * retries loading the lineup |

On Roku TVs, **\*** during full-screen video opens the TV's own picture settings, so the app's playback options use **OK**.

**Deep links:** launching the app with `contentId` set to a channel id (such as `primetime`) or a dial number (such as `8` or `300`) opens that channel full screen. See [Roku certification](docs/ROKU_CERTIFICATION.md) for test commands.

## Live data

The lineup, schedules and program details load from Spelunkr's public guide data each time the app opens. Listings from the last hour or so are kept on the Roku, so the guide fills in at once on a relaunch and then refreshes from the live data in the background. While it runs, the app checks Spelunkr's small `live.json` once a minute and loads the lineup again only when Spelunkr publishes a change, as Spelunkr asks of TV apps; it identifies itself as `spelunkr-roku/<version>`. Video plays from Internet Archive. New channels on Spelunkr appear in the app once they are added to its channel list and logo set; see [Building](docs/BUILDING.md). The app does not host, record or modify video.

Playback depends on the program's current Internet Archive file. A stream downloads its index before the picture appears; the static and `TUNING IN` timer cover that wait, which can take most of a minute on the longest tapes, and `NO SIGNAL` means the stream failed after retries.

**Weather (optional):** when you enter a ZIP code, postcode or town, the app sends only that and the country you picked to [Zippopotam.us](https://zippopotam.us) or [Open-Meteo's place search](https://open-meteo.com/en/docs/geocoding-api) to find the place, and that place's coordinates to [Open-Meteo](https://open-meteo.com) for the current weather. None of these need an account, and nothing else about you is sent. Settings, favorites and reminders stay on your Roku.

A few SATURDAY MORNING tapes store their length in a way the Roku player cuts short, so it cannot join them live past a point partway in. The app then plays the tape from the furthest point it can reach and marks it **OUT OF SYNC**; the next program joins live again. See [Roku certification](docs/ROKU_CERTIFICATION.md#roku-player-limit-on-some-tapes) for the details.

## Development and license

The source uses a fixed set of guide rows that are reused as the list scrolls, one sliding strip for the listings, a single background worker for all listing downloads, and bundled pixel logos, so browsing stays responsive on low-end Roku models. [Build instructions](docs/BUILDING.md) cover packaging, the source archive and regenerating logos, icons, themes and the splash. [Release notes](CHANGELOG.md) describe each version.

Spelunkr TV Guide's application code is licensed under [GPL-3.0](LICENSE). Spelunkr's names, logos, channel data and the videos it schedules keep their own terms. See [THIRD_PARTY.md](THIRD_PARTY.md).

## Support Spelunkr TV Guide

If Spelunkr TV Guide is useful to you, please consider supporting the people who make it possible. Donations are optional and appreciated.

1. **Internet Archive:** every program plays from Internet Archive. [Donate to Internet Archive](https://archive.org/donate)
2. **Spelunkr:** the channels, schedules and station breaks come from Spelunkr. [Tip Spelunkr on Ko-fi](https://ko-fi.com/spelunkrtv)
3. **This Roku app:** support its development with a Bitcoin donation.

   **Bitcoin (BTC):** <img src="assets/bitcoin.svg" width="20" height="20" alt="Bitcoin" align="absmiddle"> `bc1qz8877p6vusc22qrctdj4h7w0uk2l9l9h8lwphy`

## Contact

Questions, feedback, a bug report or a custom build? Get in touch through the Spelunkr TV Guide contact form.

<p align="center">
  <a href="https://snuffy420.github.io/SpelunkrTV-Roku/docs/contact.html">
    <img src="assets/contact-button.svg" alt="Contact the developer" width="260">
  </a>
</p>
