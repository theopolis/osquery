class Librpm < Formula
  desc "The RPM Package Manager (RPM) development libraries"
  homepage "http://rpm.org/"
  url "http://rpm.org/releases/testing/rpm-4.13.0-rc1.tar.bz2"
  version "4.13.0-rc1"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "abc08ac0b701ebc7da9e1334e73f4175fe652ee54bfdd3036ef0e36b77cd59a7" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"
    ENV.append_to_cflags "-I#{Formula["nss"].include}/nss"
    ENV.append_to_cflags "-I#{Formula["nspr"].include}/nspr"
    ENV.append_to_cflags "-I#{Formula["berkeley-db"].include}"

    args = [
      "--with-external-db",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--disable-plugins",
      "--disable-nls",
      "--disable-python",
      "--disable-ndb",
      "--disable-nss",
      "--disable-shared",
      "--without-nss",
      "--without-archive",
      "--without-beecrypt",
      "--without-lua",
      "--without-cap",
      "--without-selinux",
      "--without-libintl-prefix",
      "--without-libiconv-prefix",
      "CFLAGS=#{ENV.cflags}",
    ]

    system "./configure", "--prefix=#{prefix}", *args
    system "make"
    system "make", "install"
  end
end
