class Libgcrypt < Formula
  desc "Cryptographic library based on the code from GnuPG"
  homepage "https://directory.fsf.org/wiki/Libgcrypt"
  url "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.7.0.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.7.0.tar.bz2"
  sha256 "b0e67ea74474939913c4d9d9ef4ef5ec378efbe2bebe36389dee319c79bffa92"

  option :universal

  depends_on "libgpg-error"

  resource "config.h.ed" do
    url "https://raw.githubusercontent.com/Homebrew/patches/ec8d133/libgcrypt/config.h.ed"
    version "113198"
    sha256 "d02340651b18090f3df9eed47a4d84bed703103131378e1e493c26d7d0c7aab1"
  end

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.universal_binary if build.universal? or true

    args = [
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--disable-avx-support",
      "--enable-static",
      "--without-libgpg-error",
      "--prefix=#{prefix}",
      "--disable-asm",
      "--with-libgpg-error-prefix=#{Formula["libgpg-error"].opt_prefix}",
    ]

    system "./configure", *args
    if build.universal?
      buildpath.install resource("config.h.ed")
      system "ed -s - config.h <config.h.ed"
    end

    # Parallel builds work, but only when run as separate steps
    system "make"
    system "make", "install"
  end
end
