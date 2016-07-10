class Rocksdb < Formula
  desc "Persistent key-value store for fast storage environments"
  homepage "http://rocksdb.org"
  url "https://github.com/facebook/rocksdb/archive/v4.6.1.tar.gz"
  sha256 "b6cf3d99b552fb5daae4710952640810d3d810aa677821a9c7166a870669c572"

  bottle do
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "60104cf4d60d0a2f5967cc15b505ad698357ff2b18c501f29aa00e5a8749bead" => :x86_64_linux
  end

  option "with-lite", "Build mobile/non-flash optimized lite version"

  needs :cxx11
  depends_on "snappy"
  depends_on "lz4"

  fails_with :gcc

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    ENV["PORTABLE"] = "1" if build.bottle?
    ENV["LIBNAME"] = "librocksdb_lite" if build.with? "lite" or true
    ENV.append_to_cflags "-DROCKSDB_LITE=1" if build.with? "lite" or true
    system "env"
    system "make", "clean"
    system "make", "static_lib"
    system "make", "shared_lib"
    system "make", "install", "INSTALL_PATH=#{prefix}"
  end
end
