# sidecar-fix

Automatically restores your Sidecar display position every time you reconnect your iPad.

## Install

```sh
brew tap eva01/sidecar-fix
brew install sidecar-fix
```

## Setup (one time)

1. Connect your iPad via Sidecar and arrange it where you want in **System Settings → Displays**.
2. Run:

```sh
sidecar-fix setup   # installs the background agent
sidecar-fix save    # saves the current position
```

Done. The position is restored automatically on every reconnect.

## Commands

| Command | Description |
|---|---|
| `sidecar-fix save` | Save the current Sidecar position |
| `sidecar-fix apply` | Restore saved position immediately |
| `sidecar-fix list` | List active displays and positions |
| `sidecar-fix setup` | (Re)install the background agent |

## Logs

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

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/eva01/sidecar-fix
cd sidecar-fix
make install
sidecar-fix setup && sidecar-fix save
```
