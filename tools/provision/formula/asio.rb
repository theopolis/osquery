require File.expand_path("../Abstract/abstract-osquery-formula", __FILE__)

class Asio < AbstractOsqueryFormula
  desc "Cross-platform C++ Library for asynchronous programming"
  homepage "https://think-async.com/Asio"
  url "https://github.com/chriskohlhoff/asio/archive/asio-1-10-8.tar.gz"
  sha256 "fc475c6b737ad92b944babdc3e5dcf5837b663f54ba64055dc3d8fc4a3061372"
  head "https://github.com/chriskohlhoff/asio.git"
  version "1.10.8"

  bottle do
    root_url "https://osquery-packages.s3.amazonaws.com/bottles"
    cellar :any_skip_relocation
    sha256 "af9384c96b39a9589d8c3e9730fcdb7a6e496f10526ad63bb1f1e0a2b175610a" => :el_capitan
    sha256 "972a64dec67c501be1ef304ff2056a88dc4326162d2ce5fe1cab317a66e0d80e" => :x86_64_linux
  end

  needs :cxx11

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "libressl"

  # Use OpenSSL 1.01 (LibreSSL fork version) callback method.
  patch :DATA

  def install
    ENV.cxx11
    ENV.append "CPPFLAGS", "-DOPENSSL_NO_SSL3"

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
    ]
    args << "--enable-boost-coroutine" if build.with? "boost-coroutine"

    cd "asio"
    system "./autogen.sh"
    system "./configure", *args
    system "make", "install"
  end
end

__END__
diff --git a/asio/include/asio/ssl/impl/context.ipp b/asio/include/asio/ssl/impl/context.ipp
index 03c69c3..577feff 100644
--- a/asio/include/asio/ssl/impl/context.ipp
+++ b/asio/include/asio/ssl/impl/context.ipp
@@ -227,7 +227,7 @@ context::~context()
 {
   if (handle_)
   {
-#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
+#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER))
     void* cb_userdata = ::SSL_CTX_get_default_passwd_cb_userdata(handle_);
 #else // (OPENSSL_VERSION_NUMBER >= 0x10100000L)
     void* cb_userdata = handle_->default_passwd_callback_userdata;
@@ -238,7 +238,7 @@ context::~context()
         static_cast<detail::password_callback_base*>(
             cb_userdata);
       delete callback;
-#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
+#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER))
       ::SSL_CTX_set_default_passwd_cb_userdata(handle_, 0);
 #else // (OPENSSL_VERSION_NUMBER >= 0x10100000L)
       handle_->default_passwd_callback_userdata = 0;
@@ -577,7 +577,7 @@ asio::error_code context::use_certificate_chain(
   bio_cleanup bio = { make_buffer_bio(chain) };
   if (bio.p)
   {
-#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
+#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER))
     pem_password_cb* callback = ::SSL_CTX_get_default_passwd_cb(handle_);
     void* cb_userdata = ::SSL_CTX_get_default_passwd_cb_userdata(handle_);
 #else // (OPENSSL_VERSION_NUMBER >= 0x10100000L)
@@ -681,7 +681,7 @@ asio::error_code context::use_private_key(
 {
   ::ERR_clear_error();
 
-#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
+#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER))
     pem_password_cb* callback = ::SSL_CTX_get_default_passwd_cb(handle_);
     void* cb_userdata = ::SSL_CTX_get_default_passwd_cb_userdata(handle_);
 #else // (OPENSSL_VERSION_NUMBER >= 0x10100000L)
@@ -748,7 +748,7 @@ asio::error_code context::use_rsa_private_key(
 {
   ::ERR_clear_error();
 
-#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
+#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER))
     pem_password_cb* callback = ::SSL_CTX_get_default_passwd_cb(handle_);
     void* cb_userdata = ::SSL_CTX_get_default_passwd_cb_userdata(handle_);
 #else // (OPENSSL_VERSION_NUMBER >= 0x10100000L)
@@ -987,7 +987,7 @@ int context::verify_callback_function(int preverified, X509_STORE_CTX* ctx)
 asio::error_code context::do_set_password_callback(
     detail::password_callback_base* callback, asio::error_code& ec)
 {
-#if (OPENSSL_VERSION_NUMBER >= 0x10100000L)
+#if (OPENSSL_VERSION_NUMBER >= 0x10100000L && !defined(LIBRESSL_VERSION_NUMBER))
   void* old_callback = ::SSL_CTX_get_default_passwd_cb_userdata(handle_);
   ::SSL_CTX_set_default_passwd_cb_userdata(handle_, callback);
 #else // (OPENSSL_VERSION_NUMBER >= 0x10100000L)
