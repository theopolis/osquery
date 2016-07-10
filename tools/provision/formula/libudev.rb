class Libudev < Formula
  desc "API for enumerating and introspecting local devices"
  homepage "https://www.freedesktop.org/software/systemd/man/libudev.html"
  url "http://pkgs.fedoraproject.org/repo/pkgs/udev/udev-173.tar.bz2/91a88a359b60bbd074b024883cc0dbde/udev-173.tar.bz2"

  bottle do
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "9d0dba8a2acda7ece3ae9551ea66fddc420a9b2b2b2d1ae4913ab5c3427ee060" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    args = [
      "--disable-introspection",
      "--disable-gudev",
      "--disable-keymap",
      "--disable-mtd-probe",
      "--disable-hwdb",
      "--enable-static",
      "--disable-shared",
    ]

    system "./configure", "--prefix=#{prefix}", *args
    system "make"
    system "make", "install"
  end
end
