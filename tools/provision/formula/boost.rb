require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Boost < AbstractOsqueryFormula
  desc "Collection of portable C++ source libraries"
  homepage "https://www.boost.org/"
  license "BSL-1.0"
  url "https://dl.bintray.com/boostorg/release/1.66.0/source/boost_1_66_0.tar.gz"
  sha256 "bd0df411efd9a585e5a2212275f8762079fed8842264954675a4fddc46cfcf60"
  head "https://github.com/boostorg/boost.git"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "260f6810e5d1276f1866aff5bf0e997c12ed8ab46617ce16f5e985230ca8f062" => :sierra
    sha256 "2807ae0b29f9aae8a6eccd36e297f7ff902742bef8d7b9fb0dadbeb99341c6ca" => :x86_64_linux
  end

  depends_on "bzip2" unless OS.mac?

  def install
    ENV.cxx11

    # libdir should be set by --prefix but isn't
    bootstrap_args = [
      "--prefix=#{prefix}",
      "--libdir=#{lib}",
    ]

    bootstrap_args << "--with-toolset=cc" unless arm_build

    # layout should be synchronized with boost-python
    args = [
      "--prefix=#{prefix}",
      "--libdir=#{lib}",
      "-d2",
      "-j#{ENV.make_jobs}",
      "--layout=tagged",
      "--ignore-site-config",
      "--disable-icu",
      "--with-filesystem",
      "--with-regex",
      "--with-system",
      "--with-thread",
      "--with-coroutine",
      "--with-context",
      "threading=multi",
      "link=static",
      "optimization=space",
      "variant=release",
      "toolset=clang",
    ]

    args << "cxxflags=-std=c++11 #{ENV["CXXFLAGS"]}"

    # Fix error: bzlib.h: No such file or directory
    # and /usr/bin/ld: cannot find -lbz2
    args += [
      "include=#{HOMEBREW_PREFIX}/include",
      "linkflags=#{ENV["LDFLAGS"]}"
    ] unless OS.mac?

    system "./bootstrap.sh", *bootstrap_args

    # The B2 script will not read our user-config.
    # You will encounter: ERROR: rule "cc.init" unknown in module "toolset".
    # If the lines from project-config are moved into a --user-config b2 will
    # complain about duplicate initializations:
    #  error: duplicate initialization of clang-linux
    if OS.mac?
      inreplace "project-config.jam", "cc ;", "darwin ;"
    elsif !arm_build
      inreplace "project-config.jam", "cc ;", "clang ;"
    end

    system "./b2", "install", *args
  end
end
