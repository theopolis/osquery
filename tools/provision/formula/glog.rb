class Glog < Formula
  desc "Application-level logging library"
  homepage "https://github.com/google/glog"
  url "https://github.com/google/glog/archive/v0.3.4.tar.gz"
  sha256 "ce99d58dce74458f7656a68935d7a0c048fa7b4626566a71b7f4e545920ceb10"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "83c3d990acbcf7ffe0d90fb9e0c3017735687c1223d679824ecfe5db076c40e1" => :x86_64_linux
  end

  depends_on "gflags"

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end
end
