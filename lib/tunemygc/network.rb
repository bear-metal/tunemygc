# encoding: utf-8

require 'net/http'
require 'timeout'

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