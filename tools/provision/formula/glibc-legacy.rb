class GlibcLegacy < Formula
  desc "The GNU C Library"
  homepage "https://www.gnu.org/software/libc/download.html"
  url "http://ftpmirror.gnu.org/glibc/glibc-2.13.tar.bz2"
  sha256 "0173c92a0545e6d99a46a4fbed2da00ba26556f5c6198e2f9f1631ed5318dbb2"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "480e457f90c1fc665c93b1d93c804bd58cc4d268db8361ff20ef9fc81b0d5097" => :x86_64_linux
  end

  # Must apply patches to allow compiling with newer versions of GCC/gmake.
  # Must apply d9b965fa56350d6eea9f7f438a0714c7ffbb183f to allow compiling of
  # newer GCC (>6).
  patch :DATA

  # binutils 2.20 or later is required
  depends_on "binutils" => [:build, :recommended]

  # Linux kernel headers 2.6.19 or later are required
  depends_on "linux-headers" => [:build, :recommended]

  # osquery: Keep these side-by-side libraries in a Cellar.
  keg_only "osquery runtime"

  def install
    ENV["CFLAGS"] = "-U_FORTIFY_SOURCE -fno-stack-protector -O2"

    # osquery: Remove several environment variables
    ENV.delete "LD_RUN_PATH"
    ENV.delete "LIBRARY_PATH"
    ENV.delete "CPATH"
    ENV.delete "LD_LIBRARY_PATH"
    ENV["LDFLAGS"] = "-L/usr/local/osquery/lib"

    mkdir "build" do
      args = [
        "--disable-debug",
        "--disable-dependency-tracking",
        "--disable-silent-rules",
        "--prefix=#{prefix}",
        "--enable-obsolete-rpc",
        "--without-selinux",
        "--disable-sanity-checks",
      ] # Fix error: selinux/selinux.h: No such file or directory
      args << "--with-binutils=#{Formula["binutils"].bin}" if build.with? "binutils" or true
      args << "--with-headers=#{Formula["linux-headers"].include}" if build.with? "linux-headers" or true
      system "../configure", *args

      system "make" # Fix No rule to make target libdl.so.2 needed by sprof
      system "make", "install"
      prefix.install_symlink "lib" => "lib64"
    end
  end

  def post_install
    # Fix permissions
    chmod 0755, [lib/"ld-#{version}.so", lib/"libc-#{version}.so"]

    # Compile locale definition files
    mkdir_p lib/"locale"
    locales = ENV.map { |k, v| v if k[/^LANG$|^LC_/] && v != "C" }.compact
    locales << "en_US.UTF-8" # Required by gawk make check
    locales.uniq.each do |locale|
      lang, charmap = locale.split(".", 2)
      if !charmap.nil?
        system bin/"localedef", "-i", lang, "-f", charmap, locale
      else
        system bin/"localedef", "-i", lang, locale
      end
    end

    # Set the local time zone
    sys_localtime = Pathname.new "/etc/localtime"
    brew_localtime = Pathname.new prefix/"etc/localtime"
    (prefix/"etc").install_symlink sys_localtime if sys_localtime.exist? && !brew_localtime.exist?

    # Install ld.so symlink.
    ln_sf lib/"ld-linux-x86-64.so.2", HOMEBREW_PREFIX/"lib/ld.so"
  end

  test do
    system "#{lib}/ld-#{version}.so 2>&1 |grep Usage"
    system "#{lib}/libc-#{version}.so", "--version"
    system "#{bin}/locale", "--version"
  end
end

__END__
diff -Nur glibc-2.12.2/configure glibc-2.12.2-patched/configure
--- glibc-2.12.2/configure  2010-12-13 02:47:26.000000000 -0800
+++ glibc-2.12.2-patched/configure  2016-07-16 01:26:38.910295069 -0700
@@ -5189,7 +5189,7 @@
   ac_prog_version=`$CC -v 2>&1 | sed -n 's/^.*version \([egcygnustpi-]*[0-9.]*\).*$/\1/p'`
   case $ac_prog_version in
     '') ac_prog_version="v. ?.??, bad"; ac_verc_fail=yes;;
-    3.4* | 4.[0-9]* )
+    3.4* | 4.[0-9]* | 5.[0-9]* )
        ac_prog_version="$ac_prog_version, ok"; ac_verc_fail=no;;
     *) ac_prog_version="$ac_prog_version, bad"; ac_verc_fail=yes;;
 
@@ -5252,7 +5252,7 @@
   ac_prog_version=`$MAKE --version 2>&1 | sed -n 's/^.*GNU Make[^0-9]*\([0-9][0-9.]*\).*$/\1/p'`
   case $ac_prog_version in
     '') ac_prog_version="v. ?.??, bad"; ac_verc_fail=yes;;
-    3.79* | 3.[89]*)
+    3.79* | 3.[89]* | 4.[0-9]* )
        ac_prog_version="$ac_prog_version, ok"; ac_verc_fail=no;;
     *) ac_prog_version="$ac_prog_version, bad"; ac_verc_fail=yes;;
 
diff -Nur glibc-2.12.2/math/bits/mathcalls.h glibc-2.12.2-patched/math/bits/mathcalls.h
--- glibc-2.12.2/math/bits/mathcalls.h  2010-12-13 02:47:26.000000000 -0800
+++ glibc-2.12.2-patched/math/bits/mathcalls.h  2016-07-17 14:51:30.329424398 -0700
@@ -197,9 +197,11 @@
 _Mdouble_END_NAMESPACE
 
 #ifdef __USE_MISC
+# if !defined __cplusplus || __cplusplus < 201103L /* Conflicts with C++11.  */
 /* Return 0 if VALUE is finite or NaN, +1 if it
    is +Infinity, -1 if it is -Infinity.  */
 __MATHDECL_1 (int,isinf,, (_Mdouble_ __value)) __attribute__ ((__const__));
+#endif
 
 /* Return nonzero if VALUE is finite and not NaN.  */
 __MATHDECL_1 (int,finite,, (_Mdouble_ __value)) __attribute__ ((__const__));
@@ -226,13 +228,14 @@
 __END_NAMESPACE_C99
 #endif
 
-
 /* Return nonzero if VALUE is not a number.  */
 __MATHDECL_1 (int,__isnan,, (_Mdouble_ __value)) __attribute__ ((__const__));
 
 #if defined __USE_MISC || defined __USE_XOPEN
+# if !defined __cplusplus || __cplusplus < 201103L /* Conflicts with C++11.  */
 /* Return nonzero if VALUE is not a number.  */
 __MATHDECL_1 (int,isnan,, (_Mdouble_ __value)) __attribute__ ((__const__));
+#endif
 
 /* Bessel functions.  */
 __MATHCALL (j0,, (_Mdouble_));
