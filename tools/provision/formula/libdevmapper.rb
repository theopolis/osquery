class Libdevmapper < Formula
  desc "Device Mapper development"
  homepage "https://www.sourceware.org/dm/"
  url "https://osquery-packages.s3.amazonaws.com/deps/LVM2.2.02.145.tar.gz"
  sha256 "98b7c4c07c485a462c6a86e1a5265757133ceea36289ead8a419af29ef39560b"

  bottle do
    cellar :any_skip_relocation
    sha256 "2a045224ba36d9e6423c232b1bde734f86620644c62ae9e5470d4f01b465c7d5" => :x86_64_linux
  end

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    args = [
      "--with-lvm1=none",
      "--disable-selinux",
    ]
    args << "--enable-static_link" if build.with? "static" or true

    system "./configure", "--prefix=#{prefix}", *args
    system "make", "libdm.device-mapper"
    cd "libdm" do
      system "make", "install"
    end
  end
end
