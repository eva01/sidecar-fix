class SidecarFix < Formula
  desc "Auto-restore Sidecar display arrangement via launchd WatchPaths"
  homepage "https://github.com/eva01/sidecar-fix"
  url "https://github.com/eva01/sidecar-fix/releases/download/v0.3.0/sidecar-fix-v0.3.0-macos.tar.gz"
  sha256 "a31010ebce537aa42030a060ff40281c39d918406f46aef6b070d7faa6c1d93a"
  version "0.3.0"
  license "MIT"

  depends_on :macos

  def install
    bin.install "sidecar-fix"
    (prefix/"com.jin.sidecar-fix.plist").write plist_content
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

  def caveats
    <<~EOS
      Run the one-time setup to install the launchd agent:

        sidecar-fix setup

      Then arrange Sidecar to your preferred position and save it:

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
