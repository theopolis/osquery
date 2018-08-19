require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libcpp < AbstractOsqueryFormula
  desc "Next-gen compiler infrastructure"
  homepage "http://llvm.org/"
  license "NCSA"
  revision 202

  stable do
    url "http://releases.llvm.org/#{llvm_version}/llvm-#{llvm_version}.src.tar.xz"
    sha256 "1ff53c915b4e761ef400b803f07261ade637b0c269d99569f18040f3dcee4408"

    # Only required to build & run Compiler-RT tests on macOS, optional otherwise.
    # https://clang.llvm.org/get_started.html
    resource "libcxx" do
      url "http://releases.llvm.org/#{llvm_version}/libcxx-#{llvm_version}.src.tar.xz"
      sha256 "70931a87bde9d358af6cb7869e7535ec6b015f7e6df64def6d2ecdd954040dd9"
    end

    resource "clang" do
      url "http://releases.llvm.org/#{llvm_version}/cfe-#{llvm_version}.src.tar.xz"
      sha256 "e07d6dd8d9ef196cfc8e8bb131cbd6a2ed0b1caf1715f9d05b0f0eeaddb6df32"
    end

    resource "libcxxabi" do
      url "http://llvm.org/releases/#{llvm_version}/libcxxabi-#{llvm_version}.src.tar.xz"
      sha256 "91c6d9c5426306ce28d0627d6a4448e7d164d6a3f64b01cb1d196003b16d641b"
    end

    resource "compiler-rt" do
      url "http://releases.llvm.org/#{llvm_version}/compiler-rt-#{llvm_version}.src.tar.xz"
      sha256 "d0cc1342cf57e9a8d52f5498da47a3b28d24ac0d39cbc92308781b3ee0cea79a"
    end

    resource "libunwind" do
      url "http://releases.llvm.org/#{llvm_version}/libunwind-#{llvm_version}.src.tar.xz"
      sha256 "256c4ed971191bde42208386c8d39e5143fa4afd098e03bd2c140c878c63f1d6"
    end
  end

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "3b4d2ed910ba7ecc47ca246b37e012c98b79490e0d3577cd71e2cbe3b2b60e80" => :x86_64_linux
  end

  depends_on "binutils"
  depends_on "cmake" => :build

  needs :cxx11

  def clang_lib
    return "#{Formula["osquery/osquery-local/llvm"].prefix}/lib/clang/#{llvm_version}/lib"
  end

  def install
    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"projects/compiler-rt").install resource("compiler-rt")
    (buildpath/"projects/libcxx").install resource("libcxx")
    (buildpath/"projects/libcxxabi").install resource("libcxxabi")
    (buildpath/"projects/libunwind").install resource("libunwind")

    # Building with Shared libs, could use LIBNAME_ENABLE_SHARED=NO.
    args = %w[
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_ENABLE_EH=ON
      -DLLVM_TARGETS_TO_BUILD=X86;ARM;AArch64
      -DLLVM_INCLUDE_EXAMPLES=OFF
      -DLLVM_INCLUDE_TESTS=OFF
      -DLIBCXX_USE_COMPILER_RT=ON
      -DLIBCXXABI_USE_COMPILER_RT=ON
      -DLIBCXXABI_USE_LLVM_UNWINDER=ON
      -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
      -DLIBFUZZER_ENABLE=YES
    ]

    # Bootstrap the Clang compiler runtimes.
    mktemp do
      system "cmake", "-G", "Unix Makefiles", buildpath/"projects/compiler-rt",
        *(std_cmake_args + args), "-DCLANG_DEFAULT_CXX_STDLIB=libstdc++"
      system "make"
      system "make", "install"
    end

    # Bootstrap and install LibCpp.
    mktemp do
      system "cmake", "-G", "Unix Makefiles", buildpath, *(std_cmake_args + args)
      cd "projects" do
        system "make", "-j#{ENV.make_jobs}"
        system "make", "install"
      end
    end

    # LibCpp is installed.
    ln_sf prefix/"lib", clang_lib

    # Now rebuild sanitizers, which need a C++ runtime.
    add_libcpp_defines!

    # LibCpp is not in the default or legacy prefix yet.
    prepend "LDFLAGS", "-L#{prefix}/lib"
    prepend "CXXFLAGS", "-cxx-isystem#{prefix}/include/c++/v1"

    mktemp do
      args1 = args
      args1 << "-DCLANG_DEFAULT_CXX_STDLIB=libc++"
      system "cmake", "-G", "Unix Makefiles", buildpath/"projects/compiler-rt",
        *(std_cmake_args + args), "-DCLANG_DEFAULT_CXX_STDLIB=libc++"
      system "make"
      system "make", "install"
    end
  end
end
