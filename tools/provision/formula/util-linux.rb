class UtilLinux < Formula
  desc "Collection of Linux utilities"
  homepage "https://github.com/karelzak/util-linux"
  url "https://www.kernel.org/pub/linux/utils/util-linux/v2.27/util-linux-2.27.1.tar.xz"
  sha256 "0a818fcdede99aec43ffe6ca5b5388bff80d162f2f7bd4541dca94fecb87a290"
  head "https://github.com/karelzak/util-linux.git"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "30768c7c552ae70de32a2fd78e188ad3b54ede324ced4838b1448b2375d97067" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

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
