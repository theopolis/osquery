class Snappy < Formula
  desc "Compression/decompression library aiming for high speed"
  homepage "https://code.google.com/p/snappy/"
  url "https://github.com/google/snappy/releases/download/1.1.3/snappy-1.1.3.tar.gz"
  sha256 "2f1e82adf0868c9e26a5a7a3115111b6da7e432ddbac268a7ca2fae2a247eef3"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "1b72b4a0fddf11a68bcb2501f3e3c6542874ea1b2b18d2ed6c359e41bf57cae3" => :el_capitan
    sha256 "59945fa416c70d21e9159f00adbf4af65896bc104746678fb05d321bb7f4d549" => :x86_64_linux
  end

  head do
    url "https://github.com/google/snappy.git"
    depends_on "automake" => :build
    depends_on "autoconf" => :build
    depends_on "libtool" => :build
  end

  option :universal

  depends_on "pkg-config" => :build

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"
    ENV.universal_binary if build.universal?
    ENV.j1 if build.stable?

    system "./autogen.sh" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <assert.h>
      #include <snappy.h>
      #include <string>
      using namespace std;
      using namespace snappy;

      int main()
      {
        string source = "Hello World!";
        string compressed, decompressed;
        Compress(source.data(), source.size(), &compressed);
        Uncompress(compressed.data(), compressed.size(), &decompressed);
        assert(source == decompressed);
        return 0;
      }
    EOS

    system ENV.cxx, "test.cpp", "-L#{lib}", "-lsnappy", "-o", "test"
    system "./test"
  end
end
