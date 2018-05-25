require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class SysrootArm < AbstractOsqueryFormula
  desc "Linaro sysroot"
  url "https://s3.amazonaws.com/osquery-packages/deps/linaro-2.25-7.2.1-x86_64_aarch64-linux-gnu-complete.tar.gz"
  sha256 "ec370c7429c6c16b7d03daba9031f69c562386208c897ac0af2f6ce3ea702622"
  version "2.25-7.2.1"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
  end

  arm_prefix

  def install
    system "cp", "-R", "aarch64-linux-gnu", prefix/"aarch64-linux-gnu"
    system "cp", "-R", "gcc-aarch64-linux-gnu", prefix/"gcc-aarch64-linux-gnu"
    ln_sf prefix/"aarch64-linux-gnu", arm_prefix
    ln_sf prefix/"gcc-aarch64-linux-gnu", arm_prefix
  end
end
