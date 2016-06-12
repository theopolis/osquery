class Libcryptsetup < Formula
  desc "Open source disk encryption libraries"
  homepage "https://gitlab.com/cryptsetup/cryptsetup"
  url "https://osquery-packages.s3.amazonaws.com/deps/cryptsetup-1.6.7.tar.gz"

  option "with-static", "Build with static linking"

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

    args = [
      "--disable-selinux",
      "--disable-udev",
      "--disable-veritysetup",
      "--disable-nls",
      "--disable-kernel_crypto",
    ]

    if build.with? "static" or true
      args << "--enable-static" << "--disable-shared"
    end

    system "./autogen.sh", "--prefix=#{prefix}", *args
    cd "lib" do
      system "make"
      system "make", "install"
    end
  end
end
