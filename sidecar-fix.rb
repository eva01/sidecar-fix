class SidecarFix < Formula
  desc "Auto-restore Sidecar display arrangement via launchd WatchPaths"
  homepage "https://github.com/eva01/mac-monitor-fix"
  url "https://github.com/eva01/mac-monitor-fix/releases/download/v0.2.0/sidecar-fix-v0.2.0-macos.tar.gz"
  sha256 "63f370616e63e54edf09986782c3f83ad18dd486064ab352fba0926f65370157"
  version "0.2.0"
  license "MIT"

  depends_on :macos

  def install
    bin.install "sidecar-fix"
    (buildpath/"com.jin.sidecar-fix.plist").write plist_content
    (buildpath/"com.jin.sidecar-fix.plist")
  end

  def plist_content
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.jin.sidecar-fix</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/sidecar-fix</string>
          <string>apply</string>
        </array>
        <key>WatchPaths</key>
        <array>
          <string>/Library/Preferences/com.apple.windowserver.displays.plist</string>
        </array>
        <key>RunAtLoad</key>
        <false/>
      </dict>
      </plist>
    EOS
  end

  def post_install
    (Dir.home + "/Library/LaunchAgents/com.jin.sidecar-fix.plist").write plist_content
    system "launchctl", "load", Dir.home + "/Library/LaunchAgents/com.jin.sidecar-fix.plist"
  end

  def caveats
    <<~EOS
      launchd agent installed and loaded. Now arrange Sidecar to your
      preferred position, then save it:

        sidecar-fix save

      The agent will automatically call `sidecar-fix apply` whenever
      /Library/Preferences/com.apple.windowserver.displays.plist changes.
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/sidecar-fix help")
    assert_match "error:", shell_output("#{bin}/sidecar-fix unknowncmd 2>&1", 1)
  end
end
