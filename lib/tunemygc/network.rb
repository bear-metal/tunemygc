# encoding: utf-8

require 'net/http'
require 'timeout'
require 'openssl'

# Ruby 2.1.x versions don't have OpenSSL::OPENSSL_LIBRARY_VERSION defined
ssl_version_const = OpenSSl.const_defined?(:OPENSSL_LIBRARY_VERSION) ? :OPENSSL_LIBRARY_VERSION : :OPENSSL_VERSION
ssl_version = OpenSSL.const_get(ssl_version_const).scan(/\d+\.\d+\.\d+/)[0]
if ssl_version.nil?
  TuneMyGc.log "!!! could not determine OpenSSL version !!!"
elsif ssl_version < "1.0.1"
  TuneMyGc.log "!!! and openssl version > 1.0.1 is required for syncing data with the configuration service !!!"
end

module TuneMyGc
  NETWORK_TIMEOUT = 30 #seconds

  def self.http_client
    uri = URI("https://#{TuneMyGc::HOST}")
    client = Net::HTTP.new(uri.host, uri.port)
    client.use_ssl = true
    client.read_timeout = NETWORK_TIMEOUT
    client
  end
end