class Libaptpkg < Formula
  desc "The low-level bindings for apt-pkg"
  homepage "https://apt.alioth.debian.org/python-apt-doc/library/apt_pkg.html"
  url "https://osquery-packages.s3.amazonaws.com/deps/apt-1.2.6.tar.gz"

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

    args = []
    args << "STATICLIBS=1" if build.with? "static" or true

    system "make", "clean"
    system "./configure", "--prefix=#{prefix}"
    system "make", "library", *args

    # apt-pkg does not include an install target.
    mkdir_p "#{prefix}/lib"
    system "cp", "bin/libapt-pkg.a", "#{prefix}/lib/"
    mkdir_p "#{prefix}/include/apt-pkg"
    system "cp include/apt-pkg/*.h #{prefix}/include/apt-pkg/"
  end
end
