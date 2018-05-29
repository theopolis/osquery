require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Libaudit < AbstractOsqueryFormula
  desc "Linux auditing framework"
  homepage "https://github.com/Distrotech/libaudit"
  license "LGPL-2.1+"
  url "https://github.com/linux-audit/audit-userspace/archive/v2.8.3.tar.gz"
  sha256 "c239e3813b84bc264aaf2f796c131c1fe02960244f789ec2bd8d88aad4561b29"
  revision 200

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "e125c3f570de727bebf14177f29d0e2cd0d89ecd85c78ed4bec3f5a135da29ad" => :x86_64_linux
  end

  def install
    system "./autogen.sh"
    system "./configure", *osquery_autoconf_flags
    cd "lib" do
      system "make"
      system "make", "install"
    end
  end
end
