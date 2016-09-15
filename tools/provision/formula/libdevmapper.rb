require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libdevmapper < AbstractOsqueryFormula
  desc "Device Mapper development"
  homepage "https://www.sourceware.org/dm/"
  url "ftp://sources.redhat.com/pub/lvm2/releases/LVM2.2.02.165.tgz"
  sha256 "98b7c4c07c485a462c6a86e1a5265757133ceea36289ead8a419af29ef39560b"
  version "2.02.165"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "e1041607e866c145ee82c3a5babc2df4942b3ac1ba905c7bc135d98a6256dbf4" => :x86_64_linux
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
