# encoding: utf-8

require 'net/http'
require 'uri'
require 'certified'
require 'timeout'

module TuneMyGc
  class Syncer
    HOST = (ENV['RUBY_GC_TUNE_HOST'] || "tunemygc.com:443").freeze
    TIMEOUT = 5 #seconds
    HEADERS = { "Content-Type" => "application/json",
                "Accept" => "application/json",
                "User-Agent" => "TuneMyGC #{TuneMyGc::VERSION}"}.freeze
    ENVIRONMENT = [ENV['RUBY_GC_TOKEN'], RUBY_VERSION, Rails.version, ENV.select {|k,v| k =~ /RUBY_GC_/ }, TuneMyGc::VERSION, GC::OPTS, GC::INTERNAL_CONSTANTS].freeze

    attr_reader :uri, :client

    def initialize(host = HOST)
      @uri = URI("http://#{host}/ruby")
      @client = Net::HTTP.new(@uri.host, @uri.port)
      @client.use_ssl = true
      @client.read_timeout = TIMEOUT
    end

    def sync(snapshotter)
      snapshots = 0
      # Fallback to Timeout if Net::HTTP read timeout fails
      Timeout.timeout(TIMEOUT + 1) do
        snapshots = snapshotter.size
        TuneMyGc.log "Syncing #{snapshots} snapshots"
        payload = snapshotter.buffer
        payload.unshift(ENVIRONMENT)
        data = ActiveSupport::JSON.encode(payload)
        response = client.post(uri.path, data, HEADERS)
        if Net::HTTPNotImplemented === response
          TuneMyGc.log "Ruby version #{RUBY_VERSION} or Rails version #{Rails.version} not supported. Failed to sync #{snapshots} snapshots"
        elsif Net::HTTPUpgradeRequired === response
          TuneMyGc.log "Agent version #{response.body} required - please upgrade. Failed to sync #{snapshots} snapshots"
        elsif Net::HTTPPreconditionFailed === response
          TuneMyGc.log "The GC is already tuned by environment variables (#{response.body}) - we respect that, doing nothing. Failed to sync #{snapshots} snapshots"
        elsif Net::HTTPBadRequest === response
          TuneMyGc.log "Invalid payload (#{response.body}). Failed to sync #{snapshots} snapshots"
        else
          ActiveSupport::JSON.decode(response.body)
        end
      end
    rescue Exception => e
      TuneMyGc.log "Failed to sync #{snapshots} snapshots (error: #{e})"
    ensure
      # Prefer to loose data points than accumulate buffers indefinitely on error or other conditions
      snapshotter.clear
    end
  end
end