# sidecar-fix

macOS resets the Sidecar display position every time you reconnect your iPad. `sidecar-fix` saves your preferred position and restores it automatically in the background.

## Install

```sh
brew tap eva01/sidecar-fix
brew install sidecar-fix
```

## Setup (one time)

1. Connect your iPad via Sidecar and arrange it where you want in **System Settings → Displays**.
2. Run:

```sh
sidecar-fix setup   # installs and starts the launchd agent
sidecar-fix save    # saves the current position
```

That's it. Every time Sidecar reconnects, the position is restored within ~7 seconds.

## Commands

| Command | Description |
|---|---|
| `sidecar-fix setup` | Install and load the launchd agent (run once after install) |
| `sidecar-fix save` | Save the current Sidecar display position |
| `sidecar-fix list` | List all active displays and their positions |
| `sidecar-fix apply` | Restore saved position immediately (one-shot) |
| `sidecar-fix daemon` | Run the background daemon (called automatically by launchd) |

## Viewing logs

Logs go to the macOS unified log — no log files, no rotation needed:

```sh
/usr/bin/log stream --predicate 'subsystem == "com.jin.sidecar-fix"' --level debug
```

## How it works

`setup` installs a `KeepAlive` launchd agent that starts `sidecar-fix daemon` at login. The daemon polls every 5 seconds using CoreGraphics to check the Sidecar display position. When it drifts, it spawns `sidecar-fix apply` via `launchctl asuser` (needed for WindowServer write access from a launchd context), which waits 2 seconds for macOS to finish its own reconfiguration then moves the display back.

When Sidecar is not connected, each poll exits immediately. CPU impact is negligible.

## Uninstall

```sh
launchctl unload ~/Library/LaunchAgents/com.jin.sidecar-fix.plist
rm ~/Library/LaunchAgents/com.jin.sidecar-fix.plist
brew uninstall sidecar-fix
brew untap eva01/sidecar-fix
```

## Build from source

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/eva01/sidecar-fix
cd sidecar-fix
make install
sidecar-fix setup
sidecar-fix save
```
