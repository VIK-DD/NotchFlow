<div align="center">

<img src="docs/icon.png" width="120" alt="NotchFlow icon" />

# NotchFlow

### Your Mac's notch, finally doing something useful 🎶

A calm little island that lives in the notch. It shows whatever you're listening to —
**Spotify, Apple Music, YouTube in a browser**, anything — and opens into a gorgeous
player when you reach for it.

[![Download](https://img.shields.io/github/v/release/VIK-DD/NotchFlow?label=Download&style=for-the-badge&color=2563eb)](https://github.com/VIK-DD/NotchFlow/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-12%2B-black?style=for-the-badge&logo=apple)](#-works-on)
[![Swift](https://img.shields.io/badge/Swift-5.7-orange?style=for-the-badge&logo=swift)](https://swift.org)
[![Universal](https://img.shields.io/badge/Universal-Intel%20%7C%20Apple%20Silicon-success?style=for-the-badge)](#-works-on)
[![No dependencies](https://img.shields.io/badge/dependencies-none-success?style=for-the-badge)](#-what-it-does)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

<br/>

<img src="docs/screenshots/banner.png" width="820" alt="NotchFlow showing the current song in the notch" />

</div>

> The notch is just… *there*. NotchFlow turns that dead space into a glanceable music
> island — quiet when you don't need it, beautiful when you do. No accounts, no tokens,
> no fuss.

---

## ✨ What it does

- 🎵 **Shows what's playing** — album art and a live equalizer hug the notch while music plays, just like iPhone's Dynamic Island.
- 🪄 **Opens on hover** — reach for the notch and it springs into a full player: cover, title, artist, and the app it's coming from.
- ⏯️ **Real controls** — play, pause, skip, and go back with a single tap.
- 📊 **Drag to seek** — scrub through the song on a smooth, live progress bar.
- 🔊 **Volume at your fingertips** — slide to set the system volume, right there.
- 🎨 **Matches the music** — the player gently tints itself to a colour from the album art.
- 🌫️ **Stays out of the way** — invisible when idle, and clicks pass right through to your menu bar.
- 🎧 **Works with everything** — Spotify, Apple Music, browsers, podcasts… if macOS can play it, NotchFlow shows it.
- 🧩 **Made to grow** — built on a small plugin system, so more widgets (battery, weather, calendar…) are on the way.

---

## 👀 A closer look

<div align="center">
<img src="docs/screenshots/expanded.png" width="720" alt="NotchFlow expanded player" />
</div>

Hover the notch → the island grows into the player above. Move away → it tucks itself
back into the bezel.

---

## 🎛️ Make it yours

Open **Preferences** from the menu-bar icon. Everything is one click:

| Setting | What it does |
|---|---|
| **Launch at Login** | Starts NotchFlow automatically when you turn on your Mac. |
| **Expand on Track Change** | When a new song starts, the island peeks out for a moment so you catch what's playing. |
| **Tint from Album Art** | Borrows a colour from the cover so the player matches the mood of each song. |
| **Always Show on Desktop** | Keeps the island visible when you're on the Desktop / Finder. |
| **Idle Opacity** | How bright the island is when you're not using it — slide from `0%` (invisible) to `100%` (always solid). |
| **Auto-hide Delay** | How many seconds it waits before fading out once you stop — anywhere from `0s` to `30s`. |

> 💡 Tip: hover to open, drag the bars to seek or change volume, and quit anytime from
> the menu-bar icon.

---

## 📥 Get it

1. Download the latest **[NotchFlow.dmg](https://github.com/VIK-DD/NotchFlow/releases/latest)**
2. Open it and drag **NotchFlow** into **Applications**.
3. Launch it — a little island appears at your notch. That's it. 🎉

> **First time only:** since the app isn't signed with a paid Apple certificate, macOS
> asks once. Right-click the app → **Open** → **Open**.

<details>
<summary>Prefer to build it yourself?</summary>

```bash
git clone https://github.com/VIK-DD/NotchFlow.git
cd NotchFlow
swift run                    # try it instantly
./scripts/make_dmg.sh        # or build the installer → build/NotchFlow.dmg
```

Needs Xcode 14+. Open the project with `open Package.swift`.

</details>

---

## 💻 Works on

Runs natively on both **Apple Silicon** and **Intel** — one universal app, no Rosetta.

| macOS | Name | Version | Status |
|:------|:-----|:-------:|:-------|
| 🟢 | **Monterey** | 12 | ✅ Fully supported *(minimum)* |
| 🟢 | **Ventura** | 13 | ✅ Fully supported |
| 🟢 | **Sonoma** | 14 | ✅ Fully supported |
| 🟢 | **Sequoia** | 15.0 – 15.3 | ✅ Fully supported |
| 🟡 | **Sequoia** | 15.4+ | ⚠️ Island works, but Apple limited system *Now Playing*, so song info may not appear |

<div align="center">

<table>
<tr><th>Chip</th><th>Status</th></tr>
<tr><td>🍎 Apple Silicon (M1–M4)</td><td>✅ Native</td></tr>
<tr><td>💻 Intel</td><td>✅ Native</td></tr>
</table>

</div>

> No notch? No problem — NotchFlow shows a neat little pill at the top-center instead.

---

## 🗑️ Uninstall

Quit from the menu-bar icon and drag **NotchFlow** to the Trash. (Turn off *Launch at
Login* first if you had it on.)

---

<div align="center">

## 📜 License

[MIT](LICENSE) © 2026 VIK-DD — do whatever you like with it.

<br/>

Made to be calm, fast, and yours · Made in Moldova 🇲🇩

</div>
