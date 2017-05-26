require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Librpm < AbstractOsqueryFormula
  desc "The RPM Package Manager (RPM) development libraries"
  homepage "http://rpm.org/"
  url "https://github.com/rpm-software-management/rpm.git",
    :revision => "3a0ecec768bad250b71369935e900341fd0ac135"
  version "4.13.0.1-1"
  revision 101

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "" => :sierra
    sha256 "b1085e25afacc142900cc48cea97f04648c94541c741dbd77965cda98795d399" => :x86_64_linux
  end

  depends_on "berkeley-db"
  depends_on "beecrypt"
  depends_on "popt"

  def install
    ENV.append "CFLAGS", "-I#{HOMEBREW_PREFIX}/include/beecrypt"
    ENV.append "LDFLAGS", "-lz -liconv" if OS.mac?

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
      "--disable-openmp",
      "--disable-plugins",
      "--disable-shared",
      "--disable-python",
      "--enable-static",
      "--with-crypto=beecrypt",
      "--with-path-sources=#{var}/lib/rpmbuild",
    ]

    args << "--with-libiconv-prefix=/usr" if OS.mac?
    ENV["PATH"] = "#{Formula["gettext"].bin}:#{ENV["PATH"]}"

    system "./autogen.sh", "--noconfigure"
    system "./configure", "--prefix=#{prefix}", *args

    if OS.mac?
      inreplace "Makefile", "--tag=CC", "--tag=CXX"
      inreplace "Makefile", "--mode=link $(CCLD)", "--mode=link $(CXX)"
    end

    # system "make", "install-data-am"
    mkdir_p "#{include}/rpm"
    system "cp", "lib/*.h", "#{include}/rpm"

    cd "lib" do
      system "make"
      system "make", "install"
    end
  end
end
