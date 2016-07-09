class Libcryptsetup < Formula
  desc "Open source disk encryption libraries"
  homepage "https://gitlab.com/cryptsetup/cryptsetup"
  url "https://osquery-packages.s3.amazonaws.com/deps/cryptsetup-1.6.7.tar.gz"

  bottle do
    cellar :any_skip_relocation
    sha256 "aad26654d31e60c1f9d2578e327c320d82ac875b42ce93a38da511a05d79f796" => :x86_64_linux
  end

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
