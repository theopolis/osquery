require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libgcrypt < AbstractOsqueryFormula
  desc "Cryptographic library based on the code from GnuPG"
  homepage "https://directory.fsf.org/wiki/Libgcrypt"
  license "LGPL-2.1+"
  url "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.3.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.8.3.tar.bz2"
  sha256 "66ec90be036747602f2b48f98312361a9180c97c68a690a5f376fa0f67d0af7c"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "8935958d65b3912c3240361455a02353ac3bea6f090bcb27307367d85299e606" => :x86_64_linux
  end

  depends_on "libgpg-error"

  resource "config.h.ed" do
    url "https://raw.githubusercontent.com/Homebrew/patches/ec8d133/libgcrypt/config.h.ed"
    version "113198"
    sha256 "d02340651b18090f3df9eed47a4d84bed703103131378e1e493c26d7d0c7aab1"
  end

  option :universal

  def install
    ENV.universal_binary if build.universal?

    args = [
      "--disable-avx-support",
      "--disable-avx2-support",
      "--disable-drng-support",
      "--disable-pclmul-support",
      "--disable-asm",
      "--with-libgpg-error-prefix=#{Formula["osquery/osquery-local/libgpg-error"].opt_prefix}",
      "--with-gpg-error-prefix=#{Formula["osquery/osquery-local/libgpg-error"].opt_prefix}",
    ]

    system "./configure", *osquery_autoconf_flags, *args
    if build.universal?
      buildpath.install resource("config.h.ed")
      system "ed -s - config.h <config.h.ed"
    end

    cd "cipher" do
      system "make"
    end

    cd "random" do
      system "make"
    end

    cd "mpi" do
      system "make"
    end

    cd "compat" do
      system "make"
    end

    cd "src" do
      system "make"
      system "make", "install"
    end
  end
end
