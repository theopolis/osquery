class Libdevmapper < Formula
  desc "Device Mapper development"
  homepage "https://www.sourceware.org/dm/"
  url "https://osquery-packages.s3.amazonaws.com/deps/LVM2.2.02.145.tar.gz"
  sha256 "98b7c4c07c485a462c6a86e1a5265757133ceea36289ead8a419af29ef39560b"

  bottle do
    cellar :any_skip_relocation
    sha256 "0d7516ddf19b57f2a900e5f720d9411f4d66ac1f92579c67832dd25b202f19a3" => :x86_64_linux
  end

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

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
