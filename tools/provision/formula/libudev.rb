require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libudev < AbstractOsqueryFormula
  desc "API for enumerating and introspecting local devices"
  homepage "https://www.freedesktop.org/software/systemd/man/libudev.html"
  license "LGPL-2.1+"
  url "https://s3.amazonaws.com/osquery-packages/deps/udev-182.tar.gz"
  sha256 "7fac46ed4ae4dbe0ea921658c900b9e950541d3eabf9da54f0f5b6163278e202"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "2e687971566da425522c4144068dc93d167522ab2973ab77e2b2e76fd292c3a4" => :x86_64_linux
  end

  def install
    args = [
      "--disable-introspection",
      "--disable-gudev",
      "--disable-keymap",
      "--disable-mtd-probe",
      "--disable-hwdb",
    ]

    inreplace "build-aux/config.sub", " arm-* ", " aarch* "

    system "./configure", *osquery_autoconf_flags, *args
    system "make"
    system "make", "install"
  end
end
