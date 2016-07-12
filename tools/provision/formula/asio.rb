class Asio < Formula
  desc "Cross-platform C++ Library for asynchronous programming"
  homepage "https://think-async.com/Asio"
  url "https://downloads.sourceforge.net/project/asio/asio/1.10.6%20%28Stable%29/asio-1.10.6.tar.bz2"
  sha256 "e0d71c40a7b1f6c1334008fb279e7361b32a063e020efd21e40d9d8ff037195e"
  head "https://github.com/chriskohlhoff/asio.git"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "8f693bfb9b82f373726dbbff76ce40fa26243c571a0e858ec7992ae19b804119" => :x86_64_linux
  end

  needs :cxx11

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "openssl"

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    if build.head?
      cd "asio"
      system "./autogen.sh"
    else
      system "autoconf" unless OS.mac?
    end
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
    ]
    args << "--enable-boost-coroutine" if build.with? "boost-coroutine"

    system "./configure", *args
    system "make", "install"
    #pkgshare.install "src/examples"
  end
end
