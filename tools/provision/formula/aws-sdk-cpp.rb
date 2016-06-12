class AwsSdkCpp < Formula
  desc "AWS SDK for C++"
  homepage "https://github.com/aws/aws-sdk-cpp"
  url "https://osquery-packages.s3.amazonaws.com/deps/aws-sdk-cpp-0.12.4.tar.gz"

  option "with-static", "Build with static linking"
  option "without-http-client", "Don't include the libcurl HTTP client"
  option "with-logging-only", "Only build logging-related SDKs"
  option "with-minimize-size", "Request size optimization"

  depends_on "cmake" => :build

  def install
    ENV.cxx11
    ENV.append_to_cflags "-fPIC"

    args = std_cmake_args
    args << "-DSTATIC_LINKING=1" if build.with? "static" or true
    args << "-DNO_HTTP_CLIENT=1" if build.without? "http-client" or true
    args << "-DBUILD_ONLY=firehose;kinesis" if build.with? "logging-only" or true
    args << "-DMINIMIZE_SIZE=ON" if build.with? "minimize-size" or true

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
