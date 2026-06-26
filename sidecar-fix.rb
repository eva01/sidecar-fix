class SidecarFix < Formula
  desc "Auto-restore Sidecar display arrangement with a lightweight launchd daemon"
  homepage "https://github.com/eva01/sidecar-fix"
  url "https://github.com/eva01/sidecar-fix/releases/download/v0.6.2/sidecar-fix-v0.6.2-macos.tar.gz"
  sha256 "0062689c47ef87da92db58b1301dec069ab46a499b22bb9a6ff2f22772ea52b5"
  version "0.6.2"
  license "MIT"

  depends_on :macos

  def install
    bin.install "sidecar-fix"
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
