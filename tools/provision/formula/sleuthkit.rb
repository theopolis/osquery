require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Sleuthkit < AbstractOsqueryFormula
  desc "Forensic toolkit"
  homepage "http://www.sleuthkit.org/"
  license "CPL-1.0 and IPL-1.0 and GPL-2.0+"
  url "https://github.com/sleuthkit/sleuthkit/archive/sleuthkit-4.6.1.tar.gz"
  sha256 "bb2c936dbc88820fc4a875bc9b610f56c6a4a61b7bc8625f86be2549a948a7a9"
  head "https://github.com/sleuthkit/sleuthkit.git"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "6864582956f4eeff6b563c8bd0775ebc8577c396bef58be5483a9260341511c9" => :sierra
    sha256 "79281239c7aeb11fee89df082a84a3bcd3b38ebbab40c8c4695d205beebd7466" => :x86_64_linux
  end

  def install
    system "./bootstrap"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-java",
                          "--disable-shared",
                          "--enable-static",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end
end
