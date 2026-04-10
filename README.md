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
| `sidecar-fix apply` | Apply saved position (called automatically by launchd) |
| `sidecar-fix list` | List all active displays and their positions |

## How it works

- `setup` installs a launchd `WatchPaths` agent that watches `/Library/Preferences/com.apple.windowserver.displays.plist`
- When that file changes (i.e. any display event), launchd runs `sidecar-fix apply`
- `apply` waits 2 seconds for macOS to finish its own reconfiguration, then moves the Sidecar display back to the saved position
- If no Sidecar display is connected, it exits silently

The agent is event-driven — nothing runs in the background between display changes.

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
