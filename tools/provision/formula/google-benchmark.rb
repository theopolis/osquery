require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class GoogleBenchmark < AbstractOsqueryFormula
  desc "C++ microbenchmark support library"
  homepage "https://github.com/google/benchmark"
  url "https://github.com/google/benchmark/archive/v1.0.0.tar.gz"
  sha256 "d2206c263fc1a7803d4b10e164e0c225f6bcf0d5e5f20b87929f137dee247b54"
  head "https://github.com/google/benchmark.git"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "cd5871ee304536d6830a2c762d5bbed72c41c8ff0cf7987b34a995cea4cb90e0" => :el_capitan
    sha256 "56ba044f1eb012b9c539c6564d4c92ca44bd16845f87b2790fb2ac09e277cd61" => :x86_64_linux
  end

  depends_on "cmake" => :build

  needs :cxx11

  def install
    osquery_setup

    ENV.cxx11
    ENV.append_to_cflags "-Wno-zero-length-array"

    system "cmake", *std_cmake_args
    system "make"
    system "make", "install"
  end
end
