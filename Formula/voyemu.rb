# Voyemu macOS Apple Silicon prerelease.
class Voyemu < Formula
  desc "Beta of the emulator of the multimedia and instrument cluster of Android-based Voyah vehicles"
  homepage "https://voyemu.com"
  url "https://github.com/voyemu/voyemu/releases/download/v1.0.0-beta1/voyemu-1.0.0-beta1-macos-arm64.tar.xz"
  sha256 "1ac53185d8c892e0e651b38be55baa0b0633693684928f92597f205ee08d7df5"
  version "1.0.0-beta1"
  license "MIT"

  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
    libexec.install "voyemu", "profiles"
    pkgshare.install "notices"
    # The launcher finds its installation root from its own location: var/voyemu holds the launcher
    # beside profiles/, and .local/ and machines/ there outlive upgrades of the keg.
    (bin/"voyemu").write_env_script var/"voyemu/voyemu", {}
  end

  def post_install
    root = var/"voyemu"
    root.mkpath
    staging = Pathname(Dir.mktmpdir("update-", root))
    profiles = root/"profiles"
    previous_profiles = staging/"previous-profiles"
    begin
      cp_r libexec/"profiles", staging
      cp libexec/"voyemu", staging
      File.rename(profiles, previous_profiles) if profiles.exist?
      begin
        File.rename(staging/"profiles", profiles)
      rescue SystemCallError
        File.rename(previous_profiles, profiles) if previous_profiles.exist?
        raise
      end
      # A new inode lets a running session keep the launcher it started with.
      File.rename(staging/"voyemu", root/"voyemu")
    ensure
      # Preserve the previous profiles if restoring them failed.
      rm_r staging if profiles.exist? || !previous_profiles.exist?
    end
  end

  def caveats
    <<~EOS
      Tools, firmware inputs and prepared machines are kept in
        #{var}/voyemu
    EOS
  end

  test do
    assert_equal "Voyemu #{version}", shell_output("#{bin}/voyemu --version").strip
  end
end
