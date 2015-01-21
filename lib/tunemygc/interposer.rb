# encoding: utf-8

require 'active_support'

module TuneMyGc
  class Interposer
    attr_reader :subscriptions
    attr_accessor :installed

    def initialize
      reset
    end

    def on_initialized
      GC.start(full_mark: true)
      TuneMyGc.install_gc_tracepoint
      TuneMyGc.log "hooked: GC tracepoints"
      TuneMyGc.snapshot(:BOOTED)

      TuneMyGc.interposer.subscriptions << ActiveSupport::Notifications.subscribe(/^start_processing.action_controller$/) do |*args|
        TuneMyGc.snapshot(:REQUEST_PROCESSING_STARTED)
      end
      TuneMyGc.log "hooked: start_processing.action_controller"

      TuneMyGc.interposer.subscriptions << ActiveSupport::Notifications.subscribe(/^process_action.action_controller$/) do |*args|
        TuneMyGc.snapshot(:REQUEST_PROCESSING_ENDED)
        TuneMyGc.interposer.check_uninstall_request_processing
      end
      TuneMyGc.log "hooked: process_action.action_controller"
    end

    def install
      return if @installed
      TuneMyGc.log "interposing"
      ActiveSupport.on_load(:after_initialize) do
        TuneMyGc.interposer.on_initialized
      end
      TuneMyGc.log "hooked: after_initialize"

      at_exit do
        if @installed
          TuneMyGc.log "at_exit"
          uninstall_request_processing
          TuneMyGc.snapshot(:TERMINATED)
          TuneMyGc.reccommendations
        end
      end
      TuneMyGc.log "hooked: at_exit"
      @installed = true
      TuneMyGc.log "interposed"
    end

    def check_uninstall_request_processing
      if ENV["RUBY_GC_TUNE_REQUESTS"]
        @requests_limit ||= Integer(ENV["RUBY_GC_TUNE_REQUESTS"])
        @requests_processed += 1
        if @requests_processed == @requests_limit
          uninstall_request_processing
          TuneMyGc.log "kamikaze after #{@requests_processed} of #{@requests_limit} requests"
        end
      end
    end

    def uninstall_request_processing
      TuneMyGc.uninstall_gc_tracepoint
      TuneMyGc.log "uninstalled GC tracepoint"
      @subscriptions.each{|s| ActiveSupport::Notifications.unsubscribe(s) }
      @subscriptions.clear
      TuneMyGc.log "cleared ActiveSupport subscriptions"
    end

    def uninstall
      uninstall_request_processing
      reset
    end

    private
    def reset
      @installed = false
      @subscriptions = []
      @requests_processed = 0
      @requests_limit = nil
    end
  end
end