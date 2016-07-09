class CppNetlib < Formula
  desc "C++ libraries for high level network programming"
  homepage "http://cpp-netlib.org"
  url "https://github.com/cpp-netlib/cpp-netlib/archive/cpp-netlib-0.12.0-final.tar.gz"
  version "0.12.0"
  sha256 "d66e264240bf607d51b8d0e743a1fa9d592d96183d27e2abdaf68b0a87e64560"

  bottle do
    cellar :any_skip_relocation
    sha256 "aa89a2e6a02730dba0314dd27ce5373b3d75642c8a664b03da9b055739277cd3" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "openssl"

  needs :cxx11

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC"

    args = [
      "-DCPP-NETLIB_BUILD_TESTS=OFF",
      "-DCPP-NETLIB_BUILD_EXAMPLES=OFF",
    ]

    # NB: Do not build examples or tests as they require submodules.
    args += std_cmake_args
    system "cmake", *args
    system "make"
    system "make", "install"
  end
end
