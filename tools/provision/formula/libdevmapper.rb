require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libdevmapper < AbstractOsqueryFormula
  desc "Device Mapper development"
  homepage "https://www.sourceware.org/dm/"
  url "https://osquery-packages.s3.amazonaws.com/deps/LVM2.2.02.145.tar.gz"
  sha256 "98b7c4c07c485a462c6a86e1a5265757133ceea36289ead8a419af29ef39560b"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "b47ac6681a082e108ae38046f3e41b64874e27631a689238fad3e521de3d2bc7" => :x86_64_linux
  end

  def install
    # When building with LLVM/clang do not expect symbol versioning information.
    inreplace "lib/misc/lib.h", "defined(__GNUC__)", "defined(__GNUC__) && !defined(__clang__)"

    args = [
      "--with-lvm1=none",
      "--disable-selinux",
      "--enable-static_link",
    ]

    system "./configure", "--prefix=#{prefix}", *args
    system "make", "libdm.device-mapper"
    cd "libdm" do
      system "make", "install"
    end
  end
end
