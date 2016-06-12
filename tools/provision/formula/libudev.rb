class Libudev < Formula
  desc "API for enumerating and introspecting local devices"
  homepage "https://www.freedesktop.org/software/systemd/man/libudev.html"
  url "http://pkgs.fedoraproject.org/repo/pkgs/udev/udev-173.tar.bz2/91a88a359b60bbd074b024883cc0dbde/udev-173.tar.bz2"

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

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
