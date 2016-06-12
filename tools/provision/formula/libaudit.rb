class Libaudit < Formula
  desc "Linux auditing framework"
  url "https://github.com/Distrotech/libaudit/archive/audit-2.4.2.tar.gz"

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
