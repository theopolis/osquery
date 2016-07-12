class Thrift < Formula
  desc "Framework for scalable cross-language services development"
  homepage "https://thrift.apache.org/"

  stable do
    url "https://www.apache.org/dyn/closer.cgi?path=/thrift/0.9.3/thrift-0.9.3.tar.gz"
    sha256 "b0740a070ac09adde04d43e852ce4c320564a292f26521c46b78e0641564969e"

    # Apply any necessary patches (none currently required)
    [
      # Example patch:
      #
      # Apply THRIFT-2201 fix from master to 0.9.1 branch (required for clang to compile with C++11 support)
      # %w{836d95f9f00be73c6936d407977796181d1a506c f8e14cbae1810ade4eab49d91e351459b055c81dba144c1ca3c5d6f4fe440925},
    ].each do |name, sha|
      patch do
        url "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=commitdiff_plain;h=#{name}"
        sha256 sha
      end
    end
  end

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    prefix "/usr/local/osquery"
    cellar "/usr/local/osquery/Cellar"
    sha256 "2cb8f242394ff575949d7734f3feb014d70112b280a30dfbf792e7274a142403" => :x86_64_linux
  end

  depends_on "bison" => :build
  depends_on "openssl"
  depends_on :python => :optional

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC -DNDEBUG"
    ENV["PY_PREFIX"] = prefix

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
      "--without-node",
      "--with-cpp",
      "--with-python",
      "--with-openssl=#{Formula["openssl"]}"
    ]

    system "./bootstrap.sh" unless build.stable?
    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--libdir=#{lib}",
                          *exclusions
    system "make", "-j#{ENV.make_jobs}"
    system "make", "install"
  end
end
