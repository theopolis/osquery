class Libdpkg < Formula
  desc "Debian package management system"
  homepage "https://wiki.debian.org/Teams/Dpkg"
  url "https://mirrors.ocf.berkeley.edu/debian/pool/main/d/dpkg/dpkg_1.18.4.tar.xz"
  mirror "https://mirrorservice.org/sites/ftp.debian.org/debian/pool/main/d/dpkg/dpkg_1.18.4.tar.xz"
  sha256 "fe89243868888ce715bf45861f26264f767d4e4dbd0d6f1a26ce60bbbbf106da"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "93a7b3d13f0be22591511563c274ab7c5eabe3d08a247e9b2363685a1ebcd2c2" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    args = [
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--disable-dselect",
      "--disable-start-stop-daemon"
    ]

    system "./configure", "--prefix=#{prefix}", *args
    cd "lib" do
      system "make"
      system "make", "install"
    end
  end
end
