# encoding: utf-8

require 'tunemygc/subscriber'

module TuneMyGc
  class StartRequestSubscriber < Subscriber
    def start(name, id, payload)
      TuneMyGc.snapshot(:PROCESSING_STARTED)
    end
  end

  class EndRequestSubscriber < Subscriber
    def finish(name, id, payload)
      TuneMyGc.snapshot(:PROCESSING_ENDED)
      TuneMyGc.interposer.check_uninstall
    end
  end
end

module TuneMyGc
  module Spies
    class ActionController
      attr_reader :subscriptions

      def initialize
        @subscriptions = []
        @requests_processed = 0
        @requests_limit = nil
      end

      def install
        @subscriptions << ActiveSupport::Notifications.subscribe(/^start_processing.action_controller$/, TuneMyGc::StartRequestSubscriber.new)
        TuneMyGc.log "hooked: start_processing.action_controller"

        @subscriptions << ActiveSupport::Notifications.subscribe(/^process_action.action_controller$/, TuneMyGc::EndRequestSubscriber.new)
        TuneMyGc.log "hooked: process_action.action_controller"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        @subscriptions.each{|s| ActiveSupport::Notifications.unsubscribe(s) }
        @subscriptions.clear
        TuneMyGc.log "cleared ActiveSupport subscriptions"
      end

      def check_uninstall
        if ENV["RUBY_GC_TUNE_REQUESTS"]
          @requests_limit ||= Integer(ENV["RUBY_GC_TUNE_REQUESTS"])
          @requests_processed += 1
          if @requests_processed == @requests_limit
            uninstall
            TuneMyGc.log "kamikaze after #{@requests_processed} of #{@requests_limit} requests"
          end
        end
      end
    end
  end
end