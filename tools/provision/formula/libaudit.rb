class Libaudit < Formula
  desc "Linux auditing framework"
  url "https://github.com/Distrotech/libaudit/archive/audit-2.4.2.tar.gz"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "93c234daa64560b91f0938af1d277f85afd1fa8a92937080603bde4aa1ed53ee" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    cd "lib" do
      system "make"
      system "make", "install"
    end
  end
end
