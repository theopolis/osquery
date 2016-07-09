class Libaudit < Formula
  desc "Linux auditing framework"
  url "https://github.com/Distrotech/libaudit/archive/audit-2.4.2.tar.gz"

  bottle do
    cellar :any_skip_relocation
    sha256 "ba2891e10f2393484a50fc4e4e53b930beb37243f5d33c4a80e73c2bc513bd33" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC"

    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    cd "lib" do
      system "make"
      system "make", "install"
    end
  end
end
