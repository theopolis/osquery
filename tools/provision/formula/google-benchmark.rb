class GoogleBenchmark < Formula
  desc "C++ microbenchmark support library"
  homepage "https://github.com/google/benchmark"
  url "https://github.com/google/benchmark/archive/v1.0.0.tar.gz"
  sha256 "d2206c263fc1a7803d4b10e164e0c225f6bcf0d5e5f20b87929f137dee247b54"
  head "https://github.com/google/benchmark.git"

  bottle do
    cellar :any_skip_relocation
    revision 1
    sha256 "0a7f140d18ec59db58e3ba1320d4bcaa65f0df4a7b81806df3f4876f69111d24" => :x86_64_linux
  end

  depends_on "cmake" => :build

  needs :cxx11

  def install
    ENV.cxx11
    ENV.append_to_cflags "-Wno-zero-length-array"

    system "cmake", *std_cmake_args
    system "make"
    system "make", "install"
  end
end
