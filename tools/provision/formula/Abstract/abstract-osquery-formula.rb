require "formula"
require "extend/ENV/shared"

class AbstractOsqueryFormula < Formula
  def setup
    @setup = ENV.has_key?('ABSTRACT_OSQUERY_FORMULA')
    ENV['ABSTRACT_OSQUERY_FORMULA'] = '1'
    return @setup
  end

  def reset(name)
    ENV.delete name
  end

  def append(name, value)
    ENV[name] = ENV.has_key?(name) ? ENV[name] + ' ' + value.to_s : value.to_s
  end

  def prepend(name, value)
    ENV[name] = ENV.has_key?(name) ? value.to_s + ' ' + ENV[name] : value.to_s
  end

  def prepend_path(name, value)
    ENV[name] = ENV.has_key?(name) ? value.to_s + ':' + ENV[name] : value.to_s
  end

  def osquery_setup(*)
    return if setup

    puts "Hello from setup osquery: #{name}"
    legacy = Formula["glibc-legacy"]
    modern = Formula["glibc"]

    # Reset compile flags for safety, we want to control them explicitly.
    reset "CFLAGS"
    reset "CXXFLAGS"

    # Reset the following since the logic within the 'std' environment does not
    # known about our legacy runtime 'glibc' formula name.
    reset "LDFLAGS"
    reset "LD_LIBRARY_PATH"
    reset "LD_RUN_PATH"
    reset "CPATH"
    reset "LIBRARY_PATH"

    if OS.linux? && !["glibc", "glibc-legacy"].include?(self.name)
      puts "This is NOT a GLIBC install..."
      # The modern runtime is not brew-linked.

      prepend_path "LD_LIBRARY_PATH", lib
      prepend_path "LD_LIBRARY_PATH", prefix

      # Set the dynamic linker and library search path.
      if ["gcc"].include?(self.name)
        puts "This is a GCC install..."
        # When building gcc, use the modern linker.
        prepend "CFLAGS", "-I#{legacy.include}"
        append "LDFLAGS", "-Wl,--dynamic-linker=#{modern.lib}/ld-linux-x86-64.so.2"
      else
        # Otherwise, when building with gcc, use the legacy linker.
        prepend "CFLAGS", "-isystem#{HOMEBREW_PREFIX}/include"
        prepend "CFLAGS", "-isystem#{legacy.include}"

        # clang wants -L in the CFLAGS.
        # These used to belong to !gcc but -lz wants the system libz.
        prepend "CFLAGS", "-L#{HOMEBREW_PREFIX}/lib"
        prepend "CFLAGS", "-L#{legacy.lib}"


        append "LDFLAGS", "-Wl,--dynamic-linker=#{legacy.lib}/ld-linux-x86-64.so.2"
        append "LDFLAGS", "-Wl,-rpath,#{legacy.lib}"

        # cmake wants this to have -I
        #prepend "CXXFLAGS", "-I/usr/local/osquery/Cellar/gcc/6.1.0/include/c++/6.1.0"
        prepend "CXXFLAGS", "-I#{HOMEBREW_PREFIX}/include"
        prepend "CXXFLAGS", "-I#{legacy.include}"
      end

      # Add a runtime search path for the legacy C implementation.
      append "LDFLAGS", "-Wl,-rpath,#{HOMEBREW_PREFIX}/lib"
      # Adding this one line to help gcc too.
      append "LDFLAGS", "-L#{HOMEBREW_PREFIX}/lib"
      # We want the legacy path to be the last thing prepended.
      prepend "LDFLAGS", "-L#{legacy.lib}"

      # llvm does NOT want these with -isystem
      # Regardless, always prefer the legacy system includes.
      #prepend "CPPFLAGS", "-isystem#{HOMEBREW_PREFIX}/include"
      #prepend "CPPFLAGS", "-isystem#{legacy.include}"

      prepend_path "LIBRARY_PATH", HOMEBREW_PREFIX/"lib"
      prepend_path "LIBRARY_PATH", legacy.lib

      # This is already set to the PREFIX
      prepend_path "LD_RUN_PATH", HOMEBREW_PREFIX/"lib"

      # Set the search path for header files.
      prepend_path "CPATH", HOMEBREW_PREFIX/"include"
    end

    # Everyone receives:
    append "CFLAGS", "-fPIC -DNDEBUG -Os -march=core2"
    append "CXXFLAGS", "-fPIC -DNDEBUG -Os -march=core2"

    self.audit
  end

  def audit
    puts ":: PATH    : " + ENV["PATH"].to_s
    puts ":: CFLAGS  : " + ENV["CFLAGS"].to_s
    puts ":: CPPFLAGS: " + ENV["CPPFLAGS"].to_s
    puts ":: CXXFLAGS: " + ENV["CXXFLAGS"].to_s
    puts ":: LDFLAGS : " + ENV["LDFLAGS"].to_s
    puts ":: CC      : " + ENV["CC"].to_s
    puts ":: CXX     : " + ENV["CXX"].to_s
    puts ""
    puts ":: CPATH           : " + ENV["CPATH"].to_s
    puts ":: LD_LIBRARY_PATH : " + ENV["LD_LIBRARY_PATH"].to_s
    puts ":: LIBRARY_PATH    : " + ENV["LIBRARY_PATH"].to_s
    puts ":: LD_RUN_PATH     : " + ENV["LD_RUN_PATH"].to_s
  end
end
