# encoding: utf-8

begin
  require 'rspec'
rescue LoadError
  require 'rspec/core'
end

module TuneMyGc
  module Spies
    class Rspec < TuneMyGc::Spies::Base
      def initialize
        @tests_processed = 0
        @tests_limit = nil
      end

      def install
        RSpec::Core.__send__(:include, hooks_module)
        TuneMyGc.log "hooked: rspec"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        RSpec::Core.__send__(:include, disabled_hooks_module)
        TuneMyGc.log "uninstalled rspec spy"
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
          RSpec.configure do |c|
            c.before(:all) { TuneMyGc.processing_started }
            c.after(:all) { TuneMyGc.processing_ended }
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
