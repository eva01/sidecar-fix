class SidecarFix < Formula
  desc "Auto-restore Sidecar display arrangement via CoreGraphics display callbacks"
  homepage "https://github.com/eva01/sidecar-fix"
  url "https://github.com/eva01/sidecar-fix/releases/download/v0.6.1/sidecar-fix-v0.6.1-macos.tar.gz"
  sha256 "abb1fddc3d74cd57f2cf3e83b06e73169911b1c244d6d96d017385ebdae3444c"
  version "0.6.1"
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

      The daemon polls every 5 seconds and automatically restores your
      saved Sidecar position whenever it drifts.

      View logs:
        log stream --predicate 'subsystem == "com.jin.sidecar-fix"' --level info
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/sidecar-fix help")
    assert_match "error:", shell_output("#{bin}/sidecar-fix unknowncmd 2>&1", 1)
  end
end
