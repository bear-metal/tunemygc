# encoding: utf-8

module TuneMyGc
  module Spies
    class Base
      def initialize
        @processed = 0
        @limit = nil
      end

      def install
        raise NotImplementedError
      end

      def uninstall
        raise NotImplementedError
      end

      def check_uninstall
        if ENV["RUBY_GC_TUNE"]
          @limit ||= parse_gc_tune
          @processed += 1
          if @processed == @limit
            uninstall
            TuneMyGc.log "kamikaze after #{@processed} of #{@limit} units of work"
          end
        end
      end

      private
      def parse_gc_tune
        Integer(ENV["RUBY_GC_TUNE"])
      rescue ArgumentError
        1
      end
    end
  end
end