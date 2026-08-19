🌐 Language / Idioma: [English](README.md) | [Português](README.pt.md)

# ⌛ Terminal Pomodoro Timer (in D)

A simple, elegant Pomodoro timer with **ultra-low RAM usage (< 3.5 MB)** and minimal CPU consumption, built with the **D programming language (Dlang)**.

Features a clean terminal aesthetic with textured characters (`░ ▒ ▓ █`), cozy ASCII campfire/hourglass animations, a large-digit clock, and a **relaxing harmonic procedural audio synthesizer alarm** (Tibetan singing bowl / zen chime / marimba style).

---

## 📸 Features

- ⏱️ **Terminal Visual Interface**: Large textured digit clock, structured frames, and warm rustic color palette (amber, terracotta, moss green).
- ⏳ **Fluid Progress Bar**: Smooth sub-block gradations (`░`, `▒`, `▓`, `█`) and dynamic percentage indicator.
- 🔥 **Character Animations**: Animated ASCII campfire/embers and visual cycle counter.
- 🎵 **Relaxing Procedural Audio Alarm**: Built-in mathematical synthesizer generating harmonic sine waves with exponential decay (no heavy static audio files, generated on-demand in memory and played asynchronously).
- ⚡ **Extremely Lightweight**: Typical footprint of ~3.4 MB RAM and ~0% CPU.
- ⌨️ **Real-Time Interactive Controls**: Instant pause, phase skipping, minute adjustments, and mute toggle.
- 🌐 **Internationalization (i18n)**: Full support for English (`en`) and Portuguese (`pt`).

---

## 🛠️ Build and Run

### Prerequisites
- D compiler (`dmd` or `ldc2`) and package manager `dub`.

### Compiling and Running with DUB:
```bash
# Direct run with DUB:
dub run

# Or build optimized release binary:
dub build --build=release
./bin/pomodoro
```

---

## 🎮 Terminal Keyboard Controls

| Key | Action |
| :--- | :--- |
| **`Space`** | Pause or Resume the timer |
| **`N`** or **`Enter`** | Skip to next phase (Work ➔ Break ➔ ...) |
| **`R`** | Reset current phase |
| **`+`** | Add 1 minute to remaining time |
| **`-`** | Subtract 1 minute from remaining time |
| **`M`** | Toggle Sound Alarm (Enable / Mute) |
| **`Q`** or **`ESC`** | Quit program and restore terminal |

---

## ⚙️ Command-Line Options (CLI)

| Option | Description | Default |
| :--- | :--- | :--- |
| `-w, --work <min>` | Focus work duration in minutes | `25` |
| `-s, --short-break <min>` | Short break duration in minutes | `5` |
| `-l, --long-break <min>` | Long break duration in minutes | `15` |
| `-c, --cycles <count>` | Focus cycles before long break | `4` |
| `-L, --lang <pt\|en>` | Interface language (`pt` or `en`) | `pt` |
| `--no-sound` | Start with sound disabled | Disabled |
| `--test-sound` | Test procedural audio synthesizer and exit | - |
| `--ascii` | Strict ASCII compatibility mode (7-bit chars only) | Disabled |
| `-h, --help` | Display this help message | - |

### Usage Examples:
```bash
# Custom durations (e.g. 50 min work, 10 min short break, 30 min long break, 3 cycles)
dub run -- -w 50 -s 10 -l 30 -c 3

# Set interface language (pt or en):
dub run -- -L en
dub run -- --lang en

# Test procedural audio synthesizer only:
dub run -- --test-sound

# Start in silent mode:
dub run -- --no-sound

# Start in strict ASCII mode:
dub run -- --ascii
```

---

## 📜 License
Distributed under the MIT License.
