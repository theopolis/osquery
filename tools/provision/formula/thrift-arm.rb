require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class ThriftArm < AbstractOsqueryFormula
  desc "Framework for scalable cross-language services development"
  homepage "https://thrift.apache.org/"
  license "Apache-2.0"
  url "https://github.com/apache/thrift/archive/0.11.0.tar.gz"
  sha256 "0e324569321a1b626381baabbb98000c8dd3a59697292dbcc71e67135af0fefd"
  revision 202

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "4d556e7005dadd0e0035fa929a25b3e616ab3903ec47288a2138121180c88633" => :sierra
    sha256 "cfdee5e7bd1d4ff3b0ead4b686620ad5784bfd5f6a51f86543729bd351002ea9" => :x86_64_linux
  end

  depends_on "bison" => :build
  depends_on "openssl"

  patch :DATA

  def install
    ENV.cxx11
    ENV.append "CPPFLAGS", "-DOPENSSL_NO_SSL3"
    ENV.append "CXXFLAGS", "-DARITHMETIC_RIGHT_SHIFT=1" if arm_build
    ENV.append "CXXFLAGS", "-DSIGNED_RIGHT_SHIFT_IS=1" if arm_build

    exclusions = [
      "--without-ruby",
      "--disable-tests",
      "--without-php_extension",
      "--without-haskell",
      "--without-java",
      "--without-perl",
      "--without-php",
      "--without-erlang",
      "--without-go",
      "--without-qt",
      "--without-qt4",
      "--without-nodejs",
      "--without-rs",
      "--without-python",
      "--with-cpp",
      "--enable-tutorial=no",
      "--with-openssl=#{Formula["osquery/osquery-local/openssl"].prefix}",
      "--with-boost=#{Formula["osquery/osquery-local/boost"].prefix}"
    ]

    ENV["THRIFT"] = "#{default_prefix}/bin/thrift"

    ENV.prepend_path "PATH", Formula["bison"].bin

    # Prevent unknown yylex.
    ENV["LIBS"] = "/usr/lib/x86_64-linux-gnu/libfl.a"

    system "./bootstrap.sh"
    system "./configure", *osquery_autoconf_flags,
                          "--libdir=#{lib}",
                          *exclusions
    system "make", "-j#{ENV.make_jobs}"
    ENV.delete "MACOSX_DEPLOYMENT_TARGET"
    system "make", "install"
  end
end

__END__
diff --git a/lib/cpp/src/thrift/transport/TServerSocket.cpp b/lib/cpp/src/thrift/transport/TServerSocket.cpp
index 87b6383..447c89d 100644
--- a/lib/cpp/src/thrift/transport/TServerSocket.cpp
+++ b/lib/cpp/src/thrift/transport/TServerSocket.cpp
@@ -584,6 +584,12 @@ shared_ptr<TTransport> TServerSocket::acceptImpl() {
         // a certain number
         continue;
       }
+
+      // Special case because we expect setuid syscalls in other threads.
+      if (THRIFT_GET_SOCKET_ERROR == EINTR) {
+        continue;
+      }
+
       int errno_copy = THRIFT_GET_SOCKET_ERROR;
       GlobalOutput.perror("TServerSocket::acceptImpl() THRIFT_POLL() ", errno_copy);
       throw TTransportException(TTransportException::UNKNOWN, "Unknown", errno_copy);
diff --git a/configure.ac b/configure.ac
index 6a7a1a5..8b4ddc2 100755
--- a/configure.ac
+++ b/configure.ac
@@ -307,12 +307,14 @@ AM_CONDITIONAL(WITH_TWISTED_TEST, [test "$have_trial" = "yes"])
 # It's distro specific and far from ideal but needed to cross test py2-3 at once.
 # TODO: find "python2" if it's 3.x
 have_py3="no"
+if test "$with_py3" = "yes";  then
 if python --version 2>&1 | grep -q "Python 2"; then
   AC_PATH_PROGS([PYTHON3], [python3 python3.5 python35 python3.4 python34])
   if test -n "$PYTHON3"; then
     have_py3="yes"
   fi
 fi
+fi
 AM_CONDITIONAL(WITH_PY3, [test "$have_py3" = "yes"])
 
 AX_THRIFT_LIB(perl, [Perl], yes)

diff --git a/configure.ac b/configure.ac
index 8b4ddc2..fed3f14 100755
--- a/configure.ac
+++ b/configure.ac
@@ -679,14 +679,14 @@ AC_CHECK_DECL([AI_ADDRCONFIG], [],
 
 AC_FUNC_ALLOCA
 AC_FUNC_FORK
-AC_FUNC_MALLOC
 AC_FUNC_MEMCMP
-AC_FUNC_REALLOC
 AC_FUNC_SELECT_ARGTYPES
 AC_FUNC_STAT
 AC_FUNC_STRERROR_R
 AC_FUNC_STRFTIME
 AC_FUNC_VPRINTF
+AC_CHECK_FUNCS([malloc])
+AC_CHECK_FUNCS([realloc])
 AC_CHECK_FUNCS([strtoul])
 AC_CHECK_FUNCS([bzero])
 AC_CHECK_FUNCS([ftruncate])
