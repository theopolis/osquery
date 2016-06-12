class Libiptables < Formula
  desc "Device Mapper development"
  homepage "http://netfilter.samba.org/"
  url "https://osquery-packages.s3.amazonaws.com/deps/iptables-1.4.21.tar.gz"

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

    args = []
    args << "--disable-shared" if build.with? "static" or true

    system "./configure", "--prefix=#{prefix}", *args
    cd "libiptc" do
      system "make", "install"
    end
    cd "include" do
      system "make", "install"
    end
  end
end
