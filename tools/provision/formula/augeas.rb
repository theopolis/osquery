require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Augeas < AbstractOsqueryFormula
  desc "A configuration editing tool and API"
  homepage "http://augeas.net/"
  url "http://download.augeas.net/augeas-1.6.0.tar.gz"
  sha256 "8ba0d9bf059e7ef52118826d1285f097b399fc7a56756ce28e053da0b3ab69b5"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
  end

  def install
    ENV.append_to_cflags "-I/usr/include/libxml2" if OS.mac?
    system "./configure", "--without-selinux", "--prefix=#{prefix}"
    system "make", "install"
  end
end
