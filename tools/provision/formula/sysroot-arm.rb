require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class SysrootArm < AbstractOsqueryFormula
  desc "Linaro sysroot using 2.17 glibc"
  url "https://s3.amazonaws.com/osquery-packages/deps/sysroot-arm-2.17-4.8.2-3.tar.gz"
  sha256 "308f0a364689473e20fbacbf4af4ccb588e6ccdcdec9de59d251106df3acefc4"
  version "2.17-4.8.2-3"
  revision 202

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
  end

  arm_prefix

  def install
    cd ".." do
      system "cp", "-R", "gcc-aarch64-linux-gnu", prefix/"gcc-aarch64-linux-gnu"
      ln_sf prefix/"gcc-aarch64-linux-gnu", arm_prefix
    end
  end
end
