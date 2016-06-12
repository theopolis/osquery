class Libdevmapper < Formula
  desc "Device Mapper development"
  homepage "https://www.sourceware.org/dm/"
  url "https://osquery-packages.s3.amazonaws.com/deps/LVM2.2.02.145.tar.gz"

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

    args = ["--with-lvm1=none"]
    args << "--enable-static_link" if build.with? "static" or true

    system "./configure", "--prefix=#{prefix}", *args
    system "make", "libdm.device-mapper"
    cd "libdm" do
      system "make", "install"
    end
  end
end
