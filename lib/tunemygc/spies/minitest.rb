# encoding: utf-8

require 'minitest'

module TuneMyGc
  module Spies
    class Minitest
      module Hooks
        def before_setup
          tunemygc_before_setup
          super
        end

        def after_teardown
          super
          tunemygc_after_teardown
        end

        private
        def tunemygc_before_setup
          TuneMyGc.snapshot(:TEST_PROCESSING_STARTED)
        end

        def tunemygc_after_teardown
          TuneMyGc.snapshot(:TEST_PROCESSING_ENDED)
        end
      end

      module DisabledHooks
        private
        def tunemygc_before_setup
          # noop
        end

        def tunemygc_after_teardown
          # noop
        end
      end

      def initialize
        @tests_processed = 0
        @tests_limit = nil
      end

      def install
        MiniTest::Unit::TestCase.__send__(:include, TuneMyGc::Spies::Minitest::Hooks)
        TuneMyGc.log "hooked: minitest"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        MiniTest::Unit::TestCase.__send__(:include, TuneMyGc::Spies::Minitest::DisabledHooks)
        TuneMyGc.log "uninstalled minitest spy"
      end

      def check_uninstall
        if ENV["RUBY_GC_TUNE_TESTS"]
          @tests_limit ||= Integer(ENV["RUBY_GC_TUNE_TESTS"])
          @tests_processed += 1
          if @tests_processed == @tests_limit
            uninstall
            TuneMyGc.log "kamikaze after #{@tests_processed} of #{@tests_limit} tests"
          end
        end
      end
    end
  end
end