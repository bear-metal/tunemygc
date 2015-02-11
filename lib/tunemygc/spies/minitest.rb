# encoding: utf-8

require 'minitest'

module TuneMyGc
  module Spies
    class Minitest
      def initialize
        @tests_processed = 0
        @tests_limit = nil
      end

      def install
        MiniTest::Unit::TestCase.__send__(:include, hooks_module)
        TuneMyGc.log "hooked: minitest"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        MiniTest::Unit::TestCase.__send__(:include, disabled_hooks_module)
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

      def hooks_module
        Module.new do
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
            TuneMyGc.snapshot(:PROCESSING_STARTED)
          end

          def tunemygc_after_teardown
            TuneMyGc.snapshot(:PROCESSING_ENDED)
            TuneMyGc.interposer.check_uninstall
          end
        end
      end

      def disabled_hooks_module
        Module.new do
          private
          def tunemygc_before_setup
            # noop
          end

          def tunemygc_after_teardown
            # noop
          end
        end
      end
    end
  end
end