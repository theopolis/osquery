class Rocksdb < Formula
  desc "Persistent key-value store for fast storage environments"
  homepage "http://rocksdb.org"
  url "https://github.com/facebook/rocksdb/archive/v4.6.1.tar.gz"
  sha256 "b6cf3d99b552fb5daae4710952640810d3d810aa677821a9c7166a870669c572"

  bottle do
    prefix "/opt/osquery-deps"
    cellar "/opt/osquery-deps/Cellar"
    revision 1
    sha256 "c3ccefd1fbab6b1937dd5513271c2199aec6ba90bfffe7a1eec25fccfb6e5ba5" => :x86_64_linux
  end

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
    system "env"
    system "make", "clean"
    system "make", "static_lib"
    system "make", "shared_lib"
    system "make", "install", "INSTALL_PATH=#{prefix}"
  end
end
