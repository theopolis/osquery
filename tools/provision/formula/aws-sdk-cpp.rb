class AwsSdkCpp < Formula
  desc "AWS SDK for C++"
  homepage "https://github.com/aws/aws-sdk-cpp"
  url "https://osquery-packages.s3.amazonaws.com/deps/aws-sdk-cpp-0.12.4.tar.gz"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "2c885ba185eb9db9f2a17fe4478bfb5044a3bc7bdaf24134ca83693365dd88e3" => :el_capitan
    sha256 "9ab0bb9efacbbc7a9f22e0b7378dbecb119d3c9fa3ec59f9dd5aa99b8504e0da" => :x86_64_linux
  end

  depends_on "cmake" => :build

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC -DNDEBUG"

    args = std_cmake_args
    args << "-DSTATIC_LINKING=1"
    args << "-DNO_HTTP_CLIENT=1"
    args << "-DBUILD_ONLY=firehose;kinesis"
    args << "-DMINIMIZE_SIZE=ON"

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end

    lib.install Dir[lib/"mac/Release/*"].select { |f| File.file? f }
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <aws/core/Version.h>
      #include <iostream>

      int main() {
          std::cout << Aws::Version::GetVersionString() << std::endl;
          return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-o", "test", "-laws-cpp-sdk-core"
    system "./test"
  end
end
