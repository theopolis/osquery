class Libaptpkg < Formula
  desc "The low-level bindings for apt-pkg"
  homepage "https://apt.alioth.debian.org/python-apt-doc/library/apt_pkg.html"
  url "https://osquery-packages.s3.amazonaws.com/deps/apt-1.2.6.tar.gz"

  bottle do
    cellar :any_skip_relocation
    sha256 "91d0ccdb8e1e03fd4846afdeccdb1a3fdf89f9b8cabad39eb31f9330750626dd" => :x86_64_linux
  end

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

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
