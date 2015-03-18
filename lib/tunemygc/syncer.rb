# encoding: utf-8

require 'tunemygc/network'

module TuneMyGc
  class Syncer
    ENVIRONMENT = [ENV['RUBY_GC_TOKEN'], RUBY_VERSION, TuneMyGc.rails_version, ENV.select {|k,v| k =~ /RUBY_GC_/ }, TuneMyGc::VERSION, GC::OPTS, GC::INTERNAL_CONSTANTS].freeze

    attr_reader :client

    def initialize(host = TuneMyGc::HOST)
      @client = TuneMyGc.http_client
    end

    def sync(snapshotter)
      if sync_required?(snapshotter)
        snapshots = snapshotter.size
        TuneMyGc.log "Syncing #{snapshots} snapshots"
        payload = [environment(snapshotter)]
        debug = ENV["RUBY_GC_TUNE_DEBUG"]
        TuneMyGc.log "=== Snapshots ===" if debug
        while !snapshotter.empty?
          snapshot = snapshotter.deq
          TuneMyGc.log(snapshot) if debug
          payload << snapshot
        end
        data = ActiveSupport::JSON.encode(payload)
        begin
          3.times do |retries|
            Timeout.timeout(NETWORK_TIMEOUT + 1) do
              response = sync_with_tuner(data, snapshots)
              if response
                if response == :retryable
                  TuneMyGc.log "Retrying in #{retries} seconds ..."
                  sleep(retries + 1)
                else
                  process_config_callback(response)
                  return true
                end
              else
                return false
              end
            end
          end
          TuneMyGc.log "Sync failed after retries ..."
          false
        ensure
          payload.clear
        end
      else
        TuneMyGc.log "Nothing to sync, discarding #{snapshotter.size} snapshots"
        false
      end
    end

    def sync_required?(snapshotter)
      return true if ENV['RUBY_GC_SYNC_ALWAYS']
      snapshotter.unit_of_work
    end

    def environment(snapshotter)
      ENVIRONMENT.dup.concat([snapshotter.stat_keys, TuneMyGc.spy_id, Socket.gethostname, Process.ppid, Process.pid])
    end

    private
    def sync_with_tuner(data, snapshots)
      response = client.post('/ruby', data, TuneMyGc::HEADERS)
      if Net::HTTPNotFound === response
        TuneMyGc.log "Invalid application token. Please generate one with 'bundle exec tunemygc <a_valid_email_address>' and set the RUBY_GC_TOKEN environment variable"
        return false
      elsif Net::HTTPNotImplemented === response
        TuneMyGc.log "Ruby version #{RUBY_VERSION} or Rails version #{TuneMyGc.rails_version} not supported. Failed to sync #{snapshots} snapshots"
        return false
      elsif Net::HTTPUpgradeRequired === response
        TuneMyGc.log "Agent version #{response.body} required - please upgrade. Failed to sync #{snapshots} snapshots"
        return false
      elsif Net::HTTPPreconditionFailed === response
        TuneMyGc.log "The GC is already tuned by environment variables (#{response.body}) - we respect that, doing nothing. Failed to sync #{snapshots} snapshots"
        return false
      elsif Net::HTTPBadRequest === response
        TuneMyGc.log "Invalid payload (#{response.body}). Failed to sync #{snapshots} snapshots"
        return false
      elsif Net::HTTPInternalServerError === response
        TuneMyGc.log "An internal error occurred (#{response.body}). Failed to sync #{snapshots} snapshots."
        return :retryable
      elsif Net::HTTPSuccess === response
        response
      else
        TuneMyGc.log "Unknown error: #{response.body}"
        return false
      end
    rescue Timeout::Error, Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED,
           EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, IOError => e
      TuneMyGc.log "Failed to sync #{snapshots} snapshots (error: #{e})"
      return :retryable
    end

    def process_config_callback(response)
      report_url = response.body.gsub(/\.json$/, '')
      TuneMyGc.log "Please visit #{report_url} to view your configuration and other Garbage Collector insights"
    end
  end
end