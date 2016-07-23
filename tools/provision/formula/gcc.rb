class Gcc < Formula
  def arch
    if Hardware::CPU.type == :intel
      if MacOS.prefer_64_bit?
        "x86_64"
      else
        "i686"
      end
    elsif Hardware::CPU.type == :ppc
      if MacOS.prefer_64_bit?
        "powerpc64"
      else
        "powerpc"
      end
    end
  end

  def osmajor
    `uname -r`.chomp
  end

  desc "GNU compiler collection"
  homepage "https://gcc.gnu.org"
  url "http://ftpmirror.gnu.org/gcc/gcc-6.1.0/gcc-6.1.0.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/gcc/gcc-6.1.0/gcc-6.1.0.tar.bz2"
  #sha256 "b84f5592e9218b73dbae612b5253035a7b34a9a1f7688d2e1bfaaf7267d5c4db"

  head "svn://gcc.gnu.org/svn/gcc/trunk"

  option "with-java", "Build the gcj compiler"
  option "with-all-languages", "Enable all compilers and languages, except Ada"
  option "with-nls", "Build with native language support (localization)"
  option "with-jit", "Build the jit compiler"
  option "without-fortran", "Build without the gfortran compiler"
  # enabling multilib on a host that can't run 64-bit results in build failures
  if OS.mac?
    option "without-multilib", "Build without multilib support" if MacOS.prefer_64_bit?
  else
    option "with-multilib", "Build with multilib support"
  end

  depends_on "zlib" unless OS.mac?
  depends_on "binutils" if build.with? "glibc"
  depends_on "gmp"
  depends_on "libmpc"
  depends_on "mpfr"
  depends_on "isl"
  depends_on "ecj" if build.with?("java") || build.with?("all-languages")

  # osquery: We add a requirement for glibc-legacy instead of glibc.
  # We want the osquery toolchain to use a "more-available" C runtime.
  depends_on "glibc-legacy"

  if MacOS.version < :leopard && OS.mac?
    # The as that comes with Tiger isn't capable of dealing with the
    # PPC asm that comes in libitm
    depends_on "cctools" => :build
  end

  fails_with :gcc_4_0
  fails_with :llvm

  # GCC bootstraps itself, so it is OK to have an incompatible C++ stdlib
  cxxstdlib_check :skip

  # The bottles are built on systems with the CLT installed, and do not work
  # out of the box on Xcode-only systems due to an incorrect sysroot.
  pour_bottle? do
    reason "The bottle needs the Xcode CLT to be installed."
    satisfy { MacOS::CLT.installed? }
  end

  def version_suffix
    version.to_s.slice(/\d/)
  end

  # Fix for libgccjit.so linkage on Darwin
  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=64089
  patch :DATA if OS.mac?

  def install
    # GCC will suffer build errors if forced to use a particular linker.
    ENV.delete "LD"

    if OS.mac? && MacOS.version < :leopard
      ENV["AS"] = ENV["AS_FOR_TARGET"] = "#{Formula["cctools"].bin}/as"
    end

    if build.with? "all-languages"
      # Everything but Ada, which requires a pre-existing GCC Ada compiler
      # (gnat) to bootstrap. GCC 4.6.0 adds go as a language option, but it is
      # currently only compilable on Linux.
      languages = %w[c c++ objc obj-c++ fortran java jit]
    else
      # C, C++ compilers are always built
      languages = %w[c c++]

      languages << "fortran" if build.with? "fortran"
      languages << "java" if build.with? "java"
      languages << "jit" if build.with? "jit"
    end

    args = []
    args << "--build=#{arch}-apple-darwin#{osmajor}" if OS.mac?
    if build.with? "glibc"
      # Fix for GCC 4.4 and older that do not support -static-libstdc++
      # gengenrtl: error while loading shared libraries: libstdc++.so.6
      mkdir_p lib
      ln_s ["/usr/lib64/libstdc++.so.6", "/lib64/libgcc_s.so.1"], lib
      binutils = Formula["binutils"].prefix/"x86_64-pc-linux-gnu/bin"
      args += [
        "--with-native-system-header-dir=#{HOMEBREW_PREFIX}/include",
        "--with-local-prefix=#{HOMEBREW_PREFIX}/local",
        "--with-build-time-tools=#{binutils}",
      ]
      # Set the search path for glibc libraries and objects.
      ENV["LIBRARY_PATH"] = "#{Formula["glibc-legacy"].lib}:#{Formula["cctools"].lib}"
    end

    args += [
      "--prefix=#{prefix}",
      ("--libdir=#{lib}/gcc/#{version_suffix}" if OS.mac?),
      "--enable-languages=#{languages.join(",")}",
      # Make most executables versioned to avoid conflicts.
      "--program-suffix=-#{version_suffix}",
      "--with-gmp=#{Formula["gmp"].opt_prefix}",
      "--with-mpfr=#{Formula["mpfr"].opt_prefix}",
      "--with-mpc=#{Formula["libmpc"].opt_prefix}",
      "--with-isl=#{Formula["isl"].opt_prefix}",
      "--with-system-zlib",
      "--enable-libstdcxx-time=yes",
      "--enable-stage1-checking",
      "--enable-checking=release",
      "--enable-lto",
      # Use 'bootstrap-debug' build configuration to force stripping of object
      # files prior to comparison during bootstrap (broken by Xcode 6.3).
      "--with-build-config=bootstrap-debug",
      "--disable-werror",
      "--with-pkgversion=Homebrew #{name} #{pkg_version} #{build.used_options*" "}".strip,
      "--with-bugurl=https://github.com/Homebrew/homebrew/issues",
    ]

    # Fix cc1: error while loading shared libraries: libisl.so.15
    args << "--with-boot-ldflags=-static-libstdc++ -static-libgcc #{ENV["LDFLAGS"]}" if OS.linux?

    # "Building GCC with plugin support requires a host that supports
    # -fPIC, -shared, -ldl and -rdynamic."
    args << "--enable-plugin" if !OS.mac? || MacOS.version > :tiger

    # The pre-Mavericks toolchain requires the older DWARF-2 debugging data
    # format to avoid failure during the stage 3 comparison of object files.
    # See: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=45248
    args << "--with-dwarf2" if OS.mac? && MacOS.version <= :mountain_lion

    args << "--disable-nls" if build.without? "nls"

    if build.with?("java") || build.with?("all-languages")
      args << "--with-ecj-jar=#{Formula["ecj"].opt_share}/java/ecj.jar"
    end

    if build.without?("multilib") || !MacOS.prefer_64_bit?
      args << "--disable-multilib"
    else
      args << "--enable-multilib"
    end

    args << "--enable-host-shared" if build.with?("jit") || build.with?("all-languages")

    # Ensure correct install names when linking against libgcc_s;
    # see discussion in https://github.com/Homebrew/homebrew/pull/34303
    inreplace "libgcc/config/t-slibgcc-darwin", "@shlib_slibdir@", "#{HOMEBREW_PREFIX}/lib/gcc/#{version_suffix}"

    # osquery: experimentation
    # args << "--disable-bootstrap"
    args << "--disable-libgomp"

    # osquery: Remove several environment variables that cause MPX/GOMP to fail.
    ENV.delete "LD_RUN_PATH" # legacy
    #ENV.delete "CXXFLAGS"
    ENV.delete "CFLAGS" # legacy
    ENV.delete "CPATH" # legacy
    #ENV.delete "CPPFLAGS"
    #ENV["CFLAGS"] = "-march=core2"

    # osquery: add the legacy glibc library search path.
    # ENV.prepend "LDFLAGS", "-L#{Formula["glibc-legacy"].lib}" # legacy
    # ENV.prepend "CPPFLAGS", "-isystem#{Formula["glibc-legacy"].include}" # legacy
    # ENV.prepend_path "LIBRARY_PATH", "#{Formula["glibc-legacy"].lib}" # legacy

    mkdir "build" do
      if OS.mac? && !MacOS::CLT.installed?
        # For Xcode-only systems, we need to tell the sysroot path.
        # "native-system-headers" will be appended
        args << "--with-native-system-header-dir=/usr/include"
        args << "--with-sysroot=#{MacOS.sdk_path}"
      end

      #system "env"
      system "../configure", *args
      #system "kmake", "bootstrap"
      system "make", "bootstrap"
      #system "make"
      system "make", "install"

      if build.with?("fortran") || build.with?("all-languages")
        bin.install_symlink bin/"gfortran-#{version_suffix}" => "gfortran"
      end

      if OS.linux?
        # Create cpp, gcc and g++ symlinks
        bin.install_symlink "cpp-#{version_suffix}" => "cpp"
        bin.install_symlink "gcc-#{version_suffix}" => "gcc"
        bin.install_symlink "g++-#{version_suffix}" => "g++"
      end
    end

    # Handle conflicts between GCC formulae and avoid interfering
    # with system compilers.
    # Since GCC 4.8 libffi stuff are no longer shipped.
    # Rename man7.
    Dir.glob(man7/"*.7") { |file| add_suffix file, version_suffix }
    # Even when suffixes are appended, the info pages conflict when
    # install-info is run. TODO fix this.
    info.rmtree

    # Rename java properties
    if build.with?("java") || build.with?("all-languages")
      config_files = [
        "#{lib}/gcc/#{version_suffix}/logging.properties",
        "#{lib}/gcc/#{version_suffix}/security/classpath.security",
        "#{lib}/gcc/#{version_suffix}/i386/logging.properties",
        "#{lib}/gcc/#{version_suffix}/i386/security/classpath.security",
      ]
      config_files.each do |file|
        add_suffix file, version_suffix if File.exist? file
      end
    end

    # Move lib64/* to lib/ on Linuxbrew
    lib64 = Pathname.new "#{lib}64"
    if lib64.directory?
      system "mv #{lib64}/* #{lib}/" # Do not use FileUtils.mv with Ruby 1.9.3
      rmdir lib64
      prefix.install_symlink "lib" => "lib64"
    end
  end

  def add_suffix(file, suffix)
    dir = File.dirname(file)
    ext = File.extname(file)
    base = File.basename(file, ext)
    File.rename file, "#{dir}/#{base}-#{suffix}#{ext}"
  end

  def post_install
    if OS.linux?
      # Create cc and c++ symlinks, unless they already exist
      homebrew_bin = Pathname.new "#{HOMEBREW_PREFIX}/bin"
      homebrew_bin.install_symlink "gcc" => "cc" unless (homebrew_bin/"cc").exist?
      homebrew_bin.install_symlink "g++" => "c++" unless (homebrew_bin/"c++").exist?

      # Create the GCC specs file
      # See https://gcc.gnu.org/onlinedocs/gcc/Spec-Files.html

      # Locate the specs file
      gcc = "gcc-#{version_suffix}"
      specs = Pathname.new(`#{bin}/#{gcc} -print-libgcc-file-name`).dirname/"specs"
      ohai "Creating the GCC specs file: #{specs}"
      raise "command failed: #{gcc} -print-libgcc-file-name" if $?.exitstatus != 0
      specs_orig = Pathname.new("#{specs}.orig")
      rm_f [specs_orig, specs]

      # Save a backup of the default specs file
      specs_string = `#{bin}/#{gcc} -dumpspecs`
      raise "command failed: #{gcc} -dumpspecs" if $?.exitstatus != 0
      specs_orig.write specs_string

      # Set the library search path
      glibc = Formula["glibc"]
      libgcc = lib/"gcc/x86_64-unknown-linux-gnu"/version
      specs.write specs_string + <<-EOS.undent
        *cpp_unique_options:
        + -isystem #{HOMEBREW_PREFIX}/include

        *link_libgcc:
        #{glibc.installed? ? "-nostdlib -L#{libgcc}" : "+"} -L#{HOMEBREW_PREFIX}/lib

        *link:
        + --dynamic-linker #{HOMEBREW_PREFIX}/lib/ld.so -rpath #{HOMEBREW_PREFIX}/lib

      EOS
    end
  end

  def caveats
    if build.with?("multilib") then <<-EOS.undent
      GCC has been built with multilib support. Notably, OpenMP may not work:
        https://gcc.gnu.org/bugzilla/show_bug.cgi?id=60670
      If you need OpenMP support you may want to
        brew reinstall gcc --without-multilib
      EOS
    end
  end

  test do
    (testpath/"hello-c.c").write <<-EOS.undent
      #include <stdio.h>
      int main()
      {
        puts("Hello, world!");
        return 0;
      }
    EOS
    system "#{bin}/gcc-#{version_suffix}", "-o", "hello-c", "hello-c.c"
    assert_equal "Hello, world!\n", `./hello-c`

    (testpath/"hello-cc.cc").write <<-EOS.undent
      #include <iostream>
      int main()
      {
        std::cout << "Hello, world!" << std::endl;
        return 0;
      }
    EOS
    system "#{bin}/g++-#{version_suffix}", "-o", "hello-cc", "hello-cc.cc"
    assert_equal "Hello, world!\n", `./hello-cc`

    if build.with?("fortran") || build.with?("all-languages")
      fixture = <<-EOS.undent
        integer,parameter::m=10000
        real::a(m), b(m)
        real::fact=0.5

        do concurrent (i=1:m)
          a(i) = a(i) + fact*b(i)
        end do
        print *, "done"
        end
      EOS
      (testpath/"in.f90").write(fixture)
      system "#{bin}/gfortran", "-c", "in.f90"
      system "#{bin}/gfortran", "-o", "test", "in.o"
      assert_equal "done", `./test`.strip
    end
  end
end
__END__
diff --git a/gcc/jit/Make-lang.in b/gcc/jit/Make-lang.in
index 44d0750..4df2a9c 100644
--- a/gcc/jit/Make-lang.in
+++ b/gcc/jit/Make-lang.in
@@ -85,8 +85,7 @@ $(LIBGCCJIT_FILENAME): $(jit_OBJS) \
	     $(jit_OBJS) libbackend.a libcommon-target.a libcommon.a \
	     $(CPPLIB) $(LIBDECNUMBER) $(LIBS) $(BACKENDLIBS) \
	     $(EXTRA_GCC_OBJS) \
-	     -Wl,--version-script=$(srcdir)/jit/libgccjit.map \
-	     -Wl,-soname,$(LIBGCCJIT_SONAME)
+	     -Wl,-install_name,$(LIBGCCJIT_SONAME)

 $(LIBGCCJIT_SONAME_SYMLINK): $(LIBGCCJIT_FILENAME)
	ln -sf $(LIBGCCJIT_FILENAME) $(LIBGCCJIT_SONAME_SYMLINK)
diff --git a/gcc/jit/jit-playback.c b/gcc/jit/jit-playback.c
index 925fa86..01cfd4b 100644
--- a/gcc/jit/jit-playback.c
+++ b/gcc/jit/jit-playback.c
@@ -2416,6 +2416,15 @@ invoke_driver (const char *ctxt_progname,
      time.  */
   ADD_ARG ("-fno-use-linker-plugin");

+#if defined (DARWIN_X86) || defined (DARWIN_PPC)
+  /* OS X's linker defaults to treating undefined symbols as errors.
+     If the context has any imported functions or globals they will be
+     undefined until the .so is dynamically-linked into the process.
+     Ensure that the driver passes in "-undefined dynamic_lookup" to the
+     linker.  */
+  ADD_ARG ("-Wl,-undefined,dynamic_lookup");
+#endif
+
   /* pex argv arrays are NULL-terminated.  */
   argvec.safe_push (NULL);
