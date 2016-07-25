require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Readline < AbstractOsqueryFormula
  desc "Library for command-line editing"
  homepage "https://tiswww.case.edu/php/chet/readline/rltop.html"
  url "http://ftpmirror.gnu.org/readline/readline-6.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz"
  version "6.3.8"
  sha256 "56ba6071b9462f980c5a72ab0023893b65ba6debb4eeb475d7a563dc65cafd43"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "bf34aeafeb8bb10cba63b7ca83fa2e5f7184c889b14ccfd3352d344d24f763b5" => :x86_64_linux
  end

  keg_only :shadowed_by_osx, <<-EOS.undent
    OS X provides the BSD libedit library, which shadows libreadline.
    In order to prevent conflicts when programs look for libreadline we are
    defaulting this GNU Readline installation to keg-only.
  EOS

  depends_on "homebrew/dupes/ncurses" => :recommended unless OS.mac?

  # Vendor the patches.
  # The mirrors are unreliable for getting the patches, and the more patches
  # there are, the more unreliable they get. Pulling this patch inline to
  # reduce bug reports.
  # Upstream patches can be found in:
  # http://git.savannah.gnu.org/cgit/readline.git
  patch do
    url "https://gist.githubusercontent.com/jacknagel/d886531fb6623b60b2af/raw/746fc543e56bc37a26ccf05d2946a45176b0894e/readline-6.3.8.diff"
    sha256 "ef4fd6f24103b8f1d1199a6254d81a0cd63329bd2449ea9b93e66caf76d7ab89"
  end

  option :universal

  def install
    osquery_setup

    ENV.universal_binary if build.universal?

    system "./configure", "--prefix=#{prefix}", "--enable-multibyte",
      ("--with-curses" if build.with? "ncurses")
    args = []
    args << "SHLIB_LIBS=-lcurses" if build.with? "ncurses"
    system "make", "install", *args

    # The 6.3 release notes say:
    #   When creating shared libraries on Mac OS X, the pathname written into the
    #   library (install_name) no longer includes the minor version number.
    # Software will link against libreadline.6.dylib instead of libreadline.6.3.dylib.
    # Therefore we create symlinks to avoid bumping the revisions on dependents.
    # This should be removed at 6.4.
    lib.install_symlink "libhistory.6.3.dylib" => "libhistory.6.2.dylib",
                        "libreadline.6.3.dylib" => "libreadline.6.2.dylib"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <stdio.h>
      #include <stdlib.h>
      #include <readline/readline.h>

      int main()
      {
        printf("%s\\n", readline("test> "));
        return 0;
      }
    EOS
    system ENV.cc, "-L", lib, "test.c", "-lreadline", "-o", "test"
    assert_equal "test> Hello, World!\nHello, World!",
      pipe_output("./test", "Hello, World!\n").strip
  end
end
