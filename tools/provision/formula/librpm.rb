class Librpm < Formula
  desc "The RPM Package Manager (RPM) development libraries"
  homepage "http://rpm.org/"
  url "http://rpm.org/releases/testing/rpm-4.13.0-rc1.tar.bz2"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    args = [
      "--disable-plugins",
      "--disable-nls",
      "--disable-dependency-tracking",
      "--disable-silent-rules",
    ]

    system "./configure", "--prefix=#{prefix}", *args
    system "make"
    system "make", "install"
  end
end
