require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Yara < AbstractOsqueryFormula
  desc "Malware identification and classification tool"
  homepage "https://github.com/plusvic/yara/"
  head "https://github.com/plusvic/yara.git"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "fe1a36ffe1a3fc52a14cc241661fce34ad16588ea80d4cb33e8d677bc0a70646" => :el_capitan
    sha256 "53be9156489716c31595a8f91e935d5f5b94decbb46db3b3f79a2f1db915dc85" => :x86_64_linux
  end

  stable do
    url "https://github.com/plusvic/yara/archive/v3.4.0.tar.gz"
    sha256 "528571ff721364229f34f6d1ff0eedc3cd5a2a75bb94727dc6578c6efe3d618b"

    # fixes a variable redefinition error with clang (fixed in HEAD)
    patch do
      url "https://github.com/VirusTotal/yara/pull/261.diff"
      sha256 "6b5c135b577a71ca1c1a5f0a15e512f5157b13dfbd08710f9679fb4cd0b47dba"
    end
  end

  depends_on "libtool" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "pcre"
  depends_on "openssl"

  def install
    osquery_setup

    ENV.cxx11

    # Use of "inline" requires gnu89 semantics
    ENV.append "CFLAGS", "-std=gnu89" if ENV.compiler == :clang

    # find Homebrew's libpcre
    ENV.append "LDFLAGS", "-L#{Formula["pcre"].opt_lib} -lpcre"

    ENV.append "CFLAGS", "-Dstrlcat=yara_strlcat"
    ENV.append "CFLAGS", "-Dstrlcpy=yara_strlcpy"
    system "./bootstrap.sh"
    system "./configure", "--disable-silent-rules",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
end
