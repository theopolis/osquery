require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Librpm < AbstractOsqueryFormula
  desc "The RPM Package Manager (RPM) development libraries"
  homepage "http://rpm.org/"
  url "https://github.com/rpm-software-management/rpm/archive/rpm-4.13.0-rc1.tar.gz"
  sha256 "8d65bc5df3056392d7fdfbe00e8f84eb0e828582aa96ef4d6b6afac35a07e8b3"
  version "4.13.0-rc1"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "038a8f25463cfd002d734dd2ddcfbc564373f35237fcc499f98638d9f3f75345" => :x86_64_linux
  end

  # This patch removes several binaries from the build and the NSS/NSPR/Beecrypt
  # dependencies. Since this formula is "lib"rpm we do not need to build the
  # signing and signature verification tools.
  patch do
    url "https://gist.githubusercontent.com/theopolis/2d3761f5f3dfab37ab2128202d9d8b7d/raw/d46805cced7c85879814d3a496c8be7ae393e2d8/rpm-4.13.0-rc1-lite.diff"
    sha256 "224acb9c483de1dafc0992c77cb2d6b6e0e2c7516880062f29fb9599a15da212"
  end

  def install
    args = [
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--with-external-db",
      "--without-selinux",
      "--without-lua",
      "--without-cap",
      "--without-archive",
      "--disable-nls",
      "--disable-rpath",
      "--disable-plugins",
      "--disable-shared",
      "--disable-python",
      "--enable-static",
    ]

    system "./autogen.sh", "--noconfigure"
    system "./configure", "--prefix=#{prefix}", *args
    system "make"
    system "make", "install"
  end
end
