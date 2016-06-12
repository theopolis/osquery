class Rocksdb < Formula
  desc "Persistent key-value store for fast storage environments"
  homepage "http://rocksdb.org"
  url "https://github.com/facebook/rocksdb/archive/v4.5.1.tar.gz"
  sha256 "c6a23a82352dd6bb6bd580db51beafe4c5efa382b16b722c100ce2e7d1a5e497"

  option "with-lite", "Build mobile/non-flash optimized lite version"

  needs :cxx11
  depends_on "snappy"
  depends_on "lz4"

  fails_with :gcc

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC"

    ENV["PORTABLE"] = "1" if build.bottle?
    ENV["LIBNAME"] = "librocksdb_lite" if build.with? "lite" or true
    ENV.append_to_cflags "-DROCKSDB_LITE=1" if build.with? "lite" or true
    system "make", "clean"
    system "make", "static_lib"
    system "make", "shared_lib"
    system "make", "install", "INSTALL_PATH=#{prefix}"
  end
end
