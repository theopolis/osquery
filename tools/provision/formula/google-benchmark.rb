class GoogleBenchmark < Formula
  desc "C++ microbenchmark support library"
  homepage "https://github.com/google/benchmark"
  url "https://github.com/google/benchmark/archive/v1.0.0.tar.gz"
  sha256 "d2206c263fc1a7803d4b10e164e0c225f6bcf0d5e5f20b87929f137dee247b54"
  head "https://github.com/google/benchmark.git"

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
