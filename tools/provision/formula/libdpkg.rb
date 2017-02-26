require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libdpkg < AbstractOsqueryFormula
  desc "Debian package management system"
  homepage "https://wiki.debian.org/Teams/Dpkg"
  url "http://download.openpkg.org/components/cache/dpkg/dpkg_1.18.22.tar.xz"
  sha256 "eaf2ae88eae71f164167f75e9229af87fa9451bc58966fdec40db265b146ad69"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "56e258f8211451485174089a8490496babcfc0ca5dd64ff4c9005d5af623e66a" => :x86_64_linux
  end

  def install
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
