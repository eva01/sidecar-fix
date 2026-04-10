import CoreGraphics
import Foundation

// MARK: - Constants

/// macOS needs ~2 s to finish its own reconfiguration before we can move the display.
let sidecarApplyDelay: TimeInterval = 2.0

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
    } catch {
        fputs("error: could not create config directory: \(error)\n", stderr)
        exit(1)
    }
    do {
        let data = try JSONEncoder().encode(arrangement)
        try data.write(to: configFile)
    } catch {
        fputs("error: could not write arrangement: \(error)\n", stderr)
        exit(1)
    }

    print("Saved: Sidecar at (\(arrangement.x), \(arrangement.y))")
}

func cmdApply() {
    guard let data = try? Data(contentsOf: configFile),
          let saved = try? JSONDecoder().decode(Arrangement.self, from: data) else {
        fputs("error: no saved arrangement — run 'sidecar-fix save' first\n", stderr)
        exit(1)
    }

    // Wait briefly for macOS to finish its own display configuration after connecting
    Thread.sleep(forTimeInterval: sidecarApplyDelay)

    guard let sidecarID = findSidecarDisplay() else {
        // No Sidecar connected — nothing to do (triggered by other display events)
        exit(0)
    }

    let current = CGDisplayBounds(sidecarID)
    if Int32(current.origin.x) == saved.x && Int32(current.origin.y) == saved.y {
        print("Already at (\(saved.x), \(saved.y)), nothing to do.")
        return
    }

    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success else {
        fputs("error: CGBeginDisplayConfiguration failed\n", stderr)
        exit(1)
    }
    CGConfigureDisplayOrigin(config!, sidecarID, saved.x, saved.y)
    let result = CGCompleteDisplayConfiguration(config!, .permanently)

    if result == .success {
        print("Applied: Sidecar moved to (\(saved.x), \(saved.y))")
    } else {
        fputs("error: CGCompleteDisplayConfiguration failed (\(result.rawValue))\n", stderr)
        exit(1)
    }
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

func cmdSetup() {
    // Resolve the plist bundled alongside the binary: <prefix>/com.jin.sidecar-fix.plist
    let binaryURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardized
    let prefixURL = binaryURL.deletingLastPathComponent().deletingLastPathComponent()
    let plistSrc = prefixURL.appendingPathComponent("com.jin.sidecar-fix.plist")

    guard FileManager.default.fileExists(atPath: plistSrc.path) else {
        fputs("error: plist not found at \(plistSrc.path)\n", stderr)
        exit(1)
    }

    let launchAgents = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents")
    let plistDst = launchAgents.appendingPathComponent("com.jin.sidecar-fix.plist")

    do {
        try FileManager.default.createDirectory(at: launchAgents, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: plistDst.path) {
            try FileManager.default.removeItem(at: plistDst)
        }
        try FileManager.default.copyItem(at: plistSrc, to: plistDst)
    } catch {
        fputs("error: could not install plist: \(error)\n", stderr)
        exit(1)
    }

    let result = Process.run("/bin/launchctl", args: ["load", plistDst.path])
    guard result == 0 else {
        fputs("error: launchctl load failed (exit \(result))\n", stderr)
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
      list   List active displays and their positions
      save   Save current Sidecar display position
      apply  Apply saved position to current Sidecar display
             (called automatically by launchd via WatchPaths)
      setup  Install and load the launchd agent (run once after brew install)
      help   Show this help message
    """)
}

// MARK: - Helpers

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
case "save":  cmdSave()
case "apply": cmdApply()
case "list":  cmdList()
case "setup": cmdSetup()
case "help":  printHelp()
default:
    fputs("error: unknown command '\(cmd)'\n", stderr)
    printHelp()
    exit(1)
}
