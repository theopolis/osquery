require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Bzip2 < AbstractOsqueryFormula
  desc "Freely available high-quality data compressor"
  homepage "http://www.bzip.org/"
  url "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
  sha256 "a2848f34fcd5d6cf47def00461fcb528a0484d8edef8208d6d2e2909dc61d9cd"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "3ddbc5d48a58566aea701441373c945625350c3150adc9abe924d78b3b11f9ca" => :x86_64_linux
  end

  keg_only :provided_by_osx

  def install
    osquery_setup

    inreplace "Makefile", "$(PREFIX)/man", "$(PREFIX)/share/man"
    # Expect -fPIC for static library.
    inreplace "Makefile", "CFLAGS=", "CFLAGS=#{ENV.cflags} "

    system "make", "install", "PREFIX=#{prefix}"

    if OS.linux?
      # Install the shared library.

      # osquery: Remove installing the shared library
      # system "make", "-f", "Makefile-libbz2_so", "clean"
      # system "make", "-f", "Makefile-libbz2_so"
      # lib.install "libbz2.so.1.0.6", "libbz2.so.1.0"
      # lib.install_symlink "libbz2.so.1.0.6" => "libbz2.so.1"
      # lib.install_symlink "libbz2.so.1.0.6" => "libbz2.so"
    end
  end

  test do
    testfilepath = testpath + "sample_in.txt"
    zipfilepath = testpath + "sample_in.txt.bz2"

    testfilepath.write "TEST CONTENT"

    system "#{bin}/bzip2", testfilepath
    system "#{bin}/bunzip2", zipfilepath

    assert_equal "TEST CONTENT", testfilepath.read
  end
end
