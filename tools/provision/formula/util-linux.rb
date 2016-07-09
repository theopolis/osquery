class UtilLinux < Formula
  desc "Collection of Linux utilities"
  homepage "https://github.com/karelzak/util-linux"
  url "https://www.kernel.org/pub/linux/utils/util-linux/v2.27/util-linux-2.27.1.tar.xz"
  sha256 "0a818fcdede99aec43ffe6ca5b5388bff80d162f2f7bd4541dca94fecb87a290"
  head "https://github.com/karelzak/util-linux.git"

  bottle do
    prefix "/opt/osquery-deps"
    cellar "/opt/osquery-deps/Cellar"
    revision 1
    sha256 "107f14d18397743cdfdefb2d568e79fc97aae130cf2f28dcb08ee1b63017d468" => :x86_64_linux
  end

  def install
    system "./configure",
      "--disable-debug",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--prefix=#{prefix}",
      # Fix chgrp: changing group of 'wall': Operation not permitted
      "--disable-use-tty-group",
      # Conflicts with coreutils.
      "--disable-kill"
    system "make", "install"
  end

  test do
    assert_match "January", shell_output("#{bin}/cal 1 2016")
  end
end
