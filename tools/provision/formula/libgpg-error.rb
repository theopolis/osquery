require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class LibgpgError < AbstractOsqueryFormula
  desc "Common error values for all GnuPG components"
  homepage "https://www.gnupg.org/related_software/libgpg-error/"
  license "LGPL-2.1+"
  url "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.27.tar.gz"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.27.tar.gz"
  sha256 "04bdc7fd12001c797cc689b007fe24909f55aa0ee1d6d6aef967d9eebf5b2461"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "660dcd0c4ef16b262d6f4d776533848b72db2ba7bd28d1970dc1d48b4dce96f4" => :x86_64_linux
  end

  def install
    ENV.universal_binary if build.universal?

    system "./configure", *osquery_autoconf_flags
    system "make", "install"
  end
end
