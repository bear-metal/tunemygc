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
          @limit ||= Integer(ENV["RUBY_GC_TUNE"])
          @processed += 1
          if @processed == @limit
            uninstall
            TuneMyGc.log "kamikaze after #{@processed} of #{@limit} units of work"
          end
        end
      end
    end
  end
end