class Lz4 < Formula
  desc "Lossless compression algorithm"
  homepage "http://www.lz4.info/"
  url "https://github.com/Cyan4973/lz4/archive/r131.tar.gz"
  version "r131"
  sha256 "9d4d00614d6b9dec3114b33d1224b6262b99ace24434c53487a0c8fd0b18cfed"
  head "https://github.com/Cyan4973/lz4.git"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "67dd3f13c112463f9d43812e42cd44a883b26d0c246312064460d1f650a5abbd" => :x86_64_linux
  end

  def install
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    input = "testing compression and decompression"
    input_file = testpath/"in"
    input_file.write input
    output_file = testpath/"out"
    system "sh", "-c", "cat #{input_file} | #{bin}/lz4 | #{bin}/lz4 -d > #{output_file}"
    assert_equal output_file.read, input
  end
end
