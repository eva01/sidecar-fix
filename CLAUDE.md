# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Install

```bash
# Compile the binary
make build                  # → ./sidecar-fix (optimized)

# Full install (build + copy binary + install launchd agent)
make install

# Uninstall
make uninstall
```

Manual compile without Make:
```bash
swiftc Sources/SidecarFix.swift -o sidecar-fix -O
```

There are no tests beyond the Homebrew formula's `test do` block (checks `help` and unknown-command exit codes).

## Architecture

Single-file Swift CLI (`Sources/SidecarFix.swift`) with no dependencies beyond macOS system frameworks:

- **`CoreGraphics`** — display enumeration (`CGGetActiveDisplayList`), bounds (`CGDisplayBounds`), and repositioning (`CGBeginDisplayConfiguration` / `CGConfigureDisplayOrigin` / `CGCompleteDisplayConfiguration`)
- **Config** — saved as JSON at `~/.config/sidecar-fix/arrangement.json` (`Arrangement` struct: `x`, `y` Int32)
- **Sidecar display detection** — `findSidecarDisplay()` returns the first active display that is neither main nor builtin
- **`apply` command** — sleeps 2 s (`sidecarApplyDelay`) before acting to let macOS finish its own reconfiguration after a display event; exits 0 silently if no Sidecar is connected (WatchPaths fires on all display changes, not just Sidecar)

## launchd Integration

`com.jin.sidecar-fix.plist` is a `WatchPaths` launchd agent that fires `sidecar-fix apply` whenever `/Library/Preferences/com.apple.windowserver.displays.plist` changes. Logs go to `/tmp/sidecar-fix.log` and `/tmp/sidecar-fix.err`.

The Homebrew formula (`sidecar-fix.rb`) packages the pre-built binary and handles `post_install` launchd loading.

## Shell Safety

Always use non-interactive flags to avoid agent hangs:
- `cp -f`, `mv -f`, `rm -f` / `rm -rf` — shell aliases may include `-i`
