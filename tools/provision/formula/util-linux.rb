require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class UtilLinux < AbstractOsqueryFormula
  desc "Collection of Linux utilities"
  homepage "https://github.com/karelzak/util-linux"
  license "GPL-2.0+"
  url "http://ftp.iij.ad.jp/pub/linux/kernel/linux/utils/util-linux/v2.27/util-linux-2.27.1.tar.gz"
  sha256 "133c14f625d40e90e73e9d200faf3f2ce87937b99f923c84e5504ac0badc71d6"
  head "https://github.com/karelzak/util-linux.git"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "79325684febb7f3b10e60a8f6ae8c0bbdccecfdc90e00a18804c041b37a0dfea" => :x86_64_linux
  end

  def install
    #system "./autogen.sh"
    system "./configure", *osquery_autoconf_flags,
      # Fix chgrp: changing group of 'wall': Operation not permitted
      "--disable-use-tty-group",
      # Conflicts with coreutils.
      "--disable-kill",
      "--with-readline=no"
    system "make", "install"
  end
end
