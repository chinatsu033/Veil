cask "veil" do
  version "VERSION"

  on_macos do
    arch arm: "arm64", intel: "amd64"

    sha256 arm:   "ARM_SHA256",
           intel: "AMD_SHA256"

    url "https://github.com/chinatsu033/Veil/releases/download/v#{version}/Veil-#{version}-macos-#{arch}.dmg"
  end

  name "Veil"
  desc "Multi-platform proxy client based on ClashMeta"
  homepage "https://github.com/chinatsu033/Veil"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "Veil.app"

  postflight do
    system_command "xattr",
                   args: ["-rd", "com.apple.quarantine", "#{appdir}/Veil.app"]
  end

  uninstall quit: "com.follow.clash"

  zap trash: [
    "~/Library/Application Support/com.follow.clash",
    "~/Library/Caches/com.follow.clash",
    "~/Library/Preferences/com.follow.clash.plist",
    "~/Library/Saved Application State/com.follow.clash.savedState",
  ]
end
