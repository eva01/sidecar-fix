import CoreGraphics
import Foundation
import os

// MARK: - Constants

/// macOS needs ~2 s to finish its own reconfiguration before we can move the display.
let sidecarApplyDelay: TimeInterval = 2.0

let logger = Logger(subsystem: "com.jin.sidecar-fix", category: "main")

// MARK: - Config

struct Arrangement: Codable {
    var x: Int32
    var y: Int32
}

let configDir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/sidecar-fix")
let configFile = configDir.appendingPathComponent("arrangement.json")

// MARK: - Display helpers

func findSidecarDisplay() -> CGDirectDisplayID? {
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    CGGetActiveDisplayList(count, &displays, &count)

    return displays.first { id in
        CGDisplayIsMain(id) == 0 && CGDisplayIsBuiltin(id) == 0
    }
}

// MARK: - Commands

func cmdSave() {
    guard let sidecarID = findSidecarDisplay() else {
        fputs("error: no Sidecar display found — is Sidecar connected?\n", stderr)
        exit(1)
    }

    let bounds = CGDisplayBounds(sidecarID)
    let arrangement = Arrangement(x: Int32(bounds.origin.x), y: Int32(bounds.origin.y))

    do {
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(arrangement)
        try data.write(to: configFile)
    } catch {
        fputs("error: could not write arrangement: \(error)\n", stderr)
        exit(1)
    }

    print("Saved: Sidecar at (\(arrangement.x), \(arrangement.y))")
}

func applyArrangement() {
    guard let data = try? Data(contentsOf: configFile),
          let saved = try? JSONDecoder().decode(Arrangement.self, from: data) else {
        fputs("error: no saved arrangement — run 'sidecar-fix save' first\n", stderr)
        exit(1)
    }

    guard let sidecarID = findSidecarDisplay() else { return }

    let current = CGDisplayBounds(sidecarID)
    if Int32(current.origin.x) == saved.x && Int32(current.origin.y) == saved.y {
        print("Already at (\(saved.x), \(saved.y)), nothing to do.")
        return
    }

    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success else {
        fputs("error: CGBeginDisplayConfiguration failed\n", stderr)
        return
    }
    CGConfigureDisplayOrigin(config!, sidecarID, saved.x, saved.y)
    let result = CGCompleteDisplayConfiguration(config!, .permanently)

    if result == .success {
        print("Applied: Sidecar moved to (\(saved.x), \(saved.y))")
    } else {
        fputs("error: CGCompleteDisplayConfiguration failed (\(result.rawValue))\n", stderr)
    }
}

func cmdApply() {
    // Wait briefly for macOS to finish its own display configuration after connecting
    Thread.sleep(forTimeInterval: sidecarApplyDelay)
    applyArrangement()
}

func cmdDaemon() {
    logger.notice("sidecar-fix daemon started")

    let binary = executableURL().path
    let uid = String(getuid())

    // Poll every 5 seconds. CGDisplayRegisterReconfigurationCallback requires a
    // WindowServer connection that launchd agents don't have, so polling is used instead.
    // 5s gives worst-case ~7s response time (5s detect + 2s apply delay) with minimal CPU.
    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
        guard let data = try? Data(contentsOf: configFile),
              let saved = try? JSONDecoder().decode(Arrangement.self, from: data),
              let sidecarID = findSidecarDisplay() else { return }

        let current = CGDisplayBounds(sidecarID)
        guard Int32(current.origin.x) != saved.x || Int32(current.origin.y) != saved.y else { return }

        logger.notice("Wrong position (\(Int(current.origin.x)), \(Int(current.origin.y))), restoring to (\(saved.x), \(saved.y))")
        // Spawn apply via launchctl asuser so it runs in the user's GUI session,
        // which has the WindowServer write access needed for CGCompleteDisplayConfiguration.
        Process.run("/bin/launchctl", args: ["asuser", uid, binary, "apply"])
    }

    RunLoop.main.run()
}

func cmdList() {
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    CGGetActiveDisplayList(count, &displays, &count)

    for id in displays {
        let b = CGDisplayBounds(id)
        let main = CGDisplayIsMain(id) != 0
        let builtin = CGDisplayIsBuiltin(id) != 0
        print("Display \(id): \(Int(b.width))x\(Int(b.height)) at (\(Int(b.origin.x)), \(Int(b.origin.y)))" +
              "\(main ? " [main]" : "")\(builtin ? " [builtin]" : "")")
    }
}

// MARK: - Setup

func executableURL() -> URL {
    // _NSGetExecutablePath returns the real path regardless of argv[0] or shell aliasing.
    var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
    var size = UInt32(PATH_MAX)
    guard _NSGetExecutablePath(&buf, &size) == 0 else {
        return URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
    }
    return URL(fileURLWithPath: String(cString: buf)).resolvingSymlinksInPath()
}

func cmdSet(_ x: Int32, _ y: Int32) {
    guard let sidecarID = findSidecarDisplay() else {
        fputs("error: no Sidecar display found — is Sidecar connected?\n", stderr)
        exit(1)
    }

    let arrangement = Arrangement(x: x, y: y)
    do {
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(arrangement)
        try data.write(to: configFile)
    } catch {
        fputs("error: could not write arrangement: \(error)\n", stderr)
        exit(1)
    }

    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success else {
        fputs("error: CGBeginDisplayConfiguration failed\n", stderr)
        exit(1)
    }
    CGConfigureDisplayOrigin(config!, sidecarID, x, y)
    let result = CGCompleteDisplayConfiguration(config!, .permanently)

    if result == .success {
        print("Set: Sidecar moved to (\(x), \(y)) and saved.")
    } else {
        fputs("error: CGCompleteDisplayConfiguration failed (\(result.rawValue))\n", stderr)
        exit(1)
    }
}

func cmdStop() {
    let plistDst = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.jin.sidecar-fix.plist")
    guard FileManager.default.fileExists(atPath: plistDst.path) else {
        fputs("error: agent plist not found — run 'sidecar-fix setup' first\n", stderr)
        exit(1)
    }
    let result = launchctlBootout(plistDst)
    if result == 0 {
        print("Daemon unloaded. Arrange Sidecar, then run: sidecar-fix save && sidecar-fix start")
    } else {
        fputs("error: launchctl bootout failed (exit \(result))\n", stderr)
        exit(1)
    }
}

func cmdStart() {
    let plistDst = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.jin.sidecar-fix.plist")
    guard FileManager.default.fileExists(atPath: plistDst.path) else {
        fputs("error: agent plist not found — run 'sidecar-fix setup' first\n", stderr)
        exit(1)
    }
    let result = launchctlBootstrap(plistDst)
    if result == 0 {
        print("Daemon loaded.")
    } else {
        fputs("error: launchctl bootstrap failed (exit \(result))\n", stderr)
        exit(1)
    }
}

func cmdUninstall() {
    let plistDst = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.jin.sidecar-fix.plist")

    if FileManager.default.fileExists(atPath: plistDst.path) {
        _ = launchctlBootout(plistDst)
        do {
            try FileManager.default.removeItem(at: plistDst)
        } catch {
            fputs("error: could not remove plist: \(error)\n", stderr)
            exit(1)
        }
        print("launchd agent unloaded and removed.")
    } else {
        print("No agent plist found — nothing to remove.")
    }
}

func cmdSetup() {
    let launchAgents = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents")
    let plistDst = launchAgents.appendingPathComponent("com.jin.sidecar-fix.plist")

    do {
        try FileManager.default.createDirectory(at: launchAgents, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: plistDst.path) {
            try FileManager.default.removeItem(at: plistDst)
        }
        try launchAgentPlist(binaryPath: launchdBinaryPath()).write(to: plistDst, atomically: true, encoding: .utf8)
    } catch {
        fputs("error: could not install plist: \(error)\n", stderr)
        exit(1)
    }

    // Boot out first in case the agent is already registered, then bootstrap.
    _ = launchctlBootout(plistDst)
    let result = launchctlBootstrap(plistDst)
    guard result == 0 else {
        fputs("error: launchctl bootstrap failed (exit \(result))\n", stderr)
        exit(1)
    }

    print("launchd agent installed and loaded.")
    print("Now arrange Sidecar to your preferred position, then run: sidecar-fix save")
}

// MARK: - Help

func printHelp() {
    print("""
    Usage: sidecar-fix <command>

    Commands:
      list       List active displays and their positions
      save       Save current Sidecar display position
      set <x> <y>  Move Sidecar to exact coordinates and save
      apply   Apply saved position (one-shot, called by launchd)
      daemon  Run as persistent daemon, polls every 5s (called by launchd)
      setup     Install and load the launchd agent (run once after brew install)
      stop      Unload the daemon (so you can reposition and save again)
      start     Reload the daemon after stop
      uninstall Unload and remove the launchd agent
      help      Show this help message
    """)
}

// MARK: - Helpers

func launchctlDomain() -> String {
    "gui/\(getuid())"
}

func launchctlBootstrap(_ plist: URL) -> Int32 {
    Process.run("/bin/launchctl", args: ["bootstrap", launchctlDomain(), plist.path])
}

func launchctlBootout(_ plist: URL) -> Int32 {
    Process.run("/bin/launchctl", args: ["bootout", launchctlDomain(), plist.path])
}

func launchdBinaryPath() -> String {
    let path = executableURL().path
    let marker = "/Cellar/sidecar-fix/"
    guard let range = path.range(of: marker) else { return path }

    let homebrewPrefix = String(path[..<range.lowerBound])
    return "\(homebrewPrefix)/opt/sidecar-fix/bin/sidecar-fix"
}

func launchAgentPlist(binaryPath: String) -> String {
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>com.jin.sidecar-fix</string>
      <key>ProgramArguments</key>
      <array>
        <string>\(binaryPath)</string>
        <string>daemon</string>
      </array>
      <key>KeepAlive</key>
      <true/>
      <key>RunAtLoad</key>
      <true/>
    </dict>
    </plist>
    """
}

extension Process {
    @discardableResult
    static func run(_ executable: String, args: [String]) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: executable)
        p.arguments = args
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }
}

// MARK: - Entry point

let args = CommandLine.arguments
let cmd = args.count > 1 ? args[1] : "help"

switch cmd {
case "save":   cmdSave()
case "set":
    guard args.count == 4, let x = Int32(args[2]), let y = Int32(args[3]) else {
        fputs("usage: sidecar-fix set <x> <y>\n", stderr)
        exit(1)
    }
    cmdSet(x, y)
case "apply":  cmdApply()
case "daemon": cmdDaemon()
case "list":   cmdList()
case "setup":     cmdSetup()
case "stop":      cmdStop()
case "start":     cmdStart()
case "uninstall": cmdUninstall()
case "help":      printHelp()
default:
    fputs("error: unknown command '\(cmd)'\n", stderr)
    printHelp()
    exit(1)
}
