# frozen_string_literal: true

# Voyemu macOS Apple Silicon prerelease.
class Voyemu < Formula
  desc "Emulator of the multimedia and cluster of Android-based Voyah vehicles"
  homepage "https://voyemu.com"
  url "https://github.com/voyemu/voyemu/releases/download/v1.0.0-beta1/voyemu-1.0.0-beta1-macos-arm64.tar.xz"
  version "1.0.0-beta1"
  sha256 "1ac53185d8c892e0e651b38be55baa0b0633693684928f92597f205ee08d7df5"
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

  # Steps stop at the first failure: a failed copy into var/voyemu/.update leaves the previous profiles
  # and launcher in place, and the next run removes the partial copy first.
  post_install_steps do
    remove "voyemu/.update", base: :var, recursive: true
    copy "profiles", "voyemu/.update/profiles", source_base: :libexec, target_base: :var, recursive: true
    copy "voyemu", "voyemu/.update/voyemu", source_base: :libexec, target_base: :var
    if_path_exists "voyemu/profiles", base: :var do
      move "voyemu/profiles", "voyemu/.update/previous-profiles", source_base: :var, target_base: :var
    end
    move "voyemu/.update/profiles", "voyemu/profiles", source_base: :var, target_base: :var
    # A new inode lets a running session keep the launcher it started with.
    move "voyemu/.update/voyemu", "voyemu/voyemu", source_base: :var, target_base: :var
    remove "voyemu/.update", base: :var, recursive: true
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
