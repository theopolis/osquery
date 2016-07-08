class Libiptables < Formula
  desc "Device Mapper development"
  homepage "http://netfilter.samba.org/"
  url "https://osquery-packages.s3.amazonaws.com/deps/iptables-1.4.21.tar.gz"
  sha256 "ce1335c91764dc87a26978bd3725c510c2564853184c6e470e0a0f785f420f89"

  option "with-static", "Build with static linking"

  patch :DATA

  def install
    ENV.append_to_cflags "-fPIC"
    ENV.append_to_cflags "-DNDEBUG" if build.without? "debug"

    args = []
    args << "--disable-shared" if build.with? "static" or true

    system "./configure", "--prefix=#{prefix}", *args
    cd "libiptc" do
      system "make", "install"
    end
    cd "include" do
      system "make", "install"
    end
  end
end

__END__
diff -Nur iptables-1.4.21/include/linux/netfilter_ipv4/ip_tables.h iptables-1.4.21-patched/include/linux/netfilter_ipv4/ip_tables.h
--- iptables-1.4.21/include/linux/netfilter_ipv4/ip_tables.h	2013-11-22 03:18:13.000000000 -0800
+++ iptables-1.4.21-patched/include/linux/netfilter_ipv4/ip_tables.h	2016-07-07 21:03:53.742011569 -0700
@@ -218,10 +218,11 @@
 static __inline__ struct xt_entry_target *
 ipt_get_target(struct ipt_entry *e)
 {
-	return (void *)e + e->target_offset;
+	return (struct ipt_entry_target *)((char *)e + e->target_offset);
 }
 
 /*
  *	Main firewall chains definitions and global var's definitions.
  */
 #endif /* _IPTABLES_H */
+
