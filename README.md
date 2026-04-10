# sidecar-fix

macOS keeps resetting the Sidecar display position whenever you reconnect your iPad. `sidecar-fix` saves your preferred position and restores it automatically via a launchd `WatchPaths` agent — no background process, zero CPU when idle.

## Install

```sh
brew tap eva01/sidecar-fix
brew install sidecar-fix
```

## Setup (one time)

1. Connect your iPad via Sidecar and drag it to your preferred position in System Settings → Displays.
2. Run:

```sh
sidecar-fix setup   # installs and loads the launchd agent
sidecar-fix save    # saves the current position
```

That's it. Every time you reconnect, the position is restored automatically.

## Commands

| Command | Description |
|---|---|
| `sidecar-fix setup` | Install and load the launchd agent |
| `sidecar-fix save` | Save current Sidecar display position |
| `sidecar-fix apply` | Apply saved position (one-shot) |
| `sidecar-fix daemon` | Run as persistent daemon (called automatically by launchd) |
| `sidecar-fix list` | List all active displays and their positions |

## How it works

- `setup` installs a `KeepAlive` launchd agent that runs `sidecar-fix daemon` at login
- The daemon polls every 5 seconds using CoreGraphics to check the Sidecar display position
- If the position has drifted, it spawns `sidecar-fix apply` via `launchctl asuser` (required for WindowServer write access from a launchd agent) which waits 2 seconds then restores the saved position
- If no Sidecar display is connected, each poll does nothing and returns immediately

CPU impact is negligible — two CoreGraphics calls and a JSON file read every 5 seconds. All log messages go to the macOS unified log (no log files):

```sh
/usr/bin/log stream --predicate 'subsystem == "com.jin.sidecar-fix"' --level debug
```

## Uninstall

```sh
launchctl unload ~/Library/LaunchAgents/com.jin.sidecar-fix.plist
rm ~/Library/LaunchAgents/com.jin.sidecar-fix.plist
brew uninstall sidecar-fix
brew untap eva01/sidecar-fix
```

## Build from source

```sh
git clone https://github.com/eva01/sidecar-fix
cd sidecar-fix
make install
sidecar-fix save
```

Requires Xcode Command Line Tools (`xcode-select --install`).
