# encoding: utf-8

require 'net/http'
require 'timeout'
require 'openssl'

ssl_version = OpenSSL::OPENSSL_LIBRARY_VERSION.scan(/\d+\.\d+\.\d+/)[0]
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