class SidecarFix < Formula
  desc "Auto-restore Sidecar display arrangement via CoreGraphics display callbacks"
  homepage "https://github.com/eva01/sidecar-fix"
  url "https://github.com/eva01/sidecar-fix/releases/download/v0.4.0/sidecar-fix-v0.4.0-macos.tar.gz"
  sha256 "4bb60b2430e1894a6e6ad8d5edfed6a9976aef16e737cacae8e6c4a05a83ff23"
  version "0.4.0"
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
          <string>daemon</string>
        </array>
        <key>KeepAlive</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/tmp/sidecar-fix.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/sidecar-fix.err</string>
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

      The daemon uses CoreGraphics callbacks to detect display changes
      and automatically restores your saved Sidecar position.
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/sidecar-fix help")
    assert_match "error:", shell_output("#{bin}/sidecar-fix unknowncmd 2>&1", 1)
  end
end
