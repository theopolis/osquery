class Yara < Formula
  desc "Malware identification and classification tool"
  homepage "https://github.com/plusvic/yara/"
  head "https://github.com/plusvic/yara.git"

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
    ENV.cxx11
    ENV.append_to_cflags "-fPIC"

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
