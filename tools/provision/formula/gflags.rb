class Gflags < Formula
  desc "Library for processing command-line flags"
  homepage "https://gflags.github.io/gflags/"
  url "https://github.com/gflags/gflags/archive/v2.1.2.tar.gz"
  sha256 "d8331bd0f7367c8afd5fcb5f5e85e96868a00fd24b7276fa5fcee1e5575c2662"

  bottle do
    cellar :any_skip_relocation
    sha256 "b458b47a92e941e3f01bda73b044d71720c5dfbc9950710797687fe95a5571bf" => :x86_64_linux
  end

  option "with-static", "Build gflags as a static (instead of shared) library."

  depends_on "cmake" => :build

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC"
    
    args = std_cmake_args
    if build.with? "static" or true
      args << "-DBUILD_SHARED_LIBS=OFF"
    else
      args << "-DBUILD_SHARED_LIBS=ON"
    end

    mkdir "buildroot" do
      system "cmake", "..", *args
      system "make", "install"
    end
  end
end
