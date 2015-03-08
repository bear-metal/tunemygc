# encoding: utf-8

require 'que'

module TuneMyGc
  module Spies
    class QueJob < TuneMyGc::Spies::Base
      def initialize
        @jobs_processed = 0
        @jobs_limit = nil
      end

      def install
        ::Que::Job.__send__(:include, TuneMyGc::Spies::QueJob::Hooks)
        TuneMyGc.log "hooked: que_job"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        ::Que::Job.__send__(:include, TuneMyGc::Spies::QueJob::DisabledHooks)
        TuneMyGc.log "uninstalled que_job spy"
      end

      def check_uninstall
        if ENV["RUBY_GC_TUNE_JOBS"]
          @jobs_limit ||= Integer(ENV["RUBY_GC_TUNE_JOBS"])
          @jobs_processed += 1
          if @jobs_processed == @jobs_limit
            uninstall
            TuneMyGc.log "kamikaze after #{@jobs_processed} of #{@jobs_limit} jobs"
          end
        end
      end

      module Hooks
        def initialize(*args)
          define_singleton_method :run do |*args|
            self.class.tunemygc_before_run
            begin
              super(*args)
            ensure
              self.class.tunemygc_after_run
            end
          end
        end

        def self.included(klass)
          klass.extend(TuneMyGc::Spies::QueJob::Hooks::ClassMethods)
        end

        module ClassMethods
          def tunemygc_before_perform
            TuneMyGc.processing_started
          end

          def tunemygc_after_perform
            TuneMyGc.processing_ended
          end
        end
      end

      module DisabledHooks
        def self.included(klass)
          klass.extend(TuneMyGc::Spies::QueJob::DisabledHooks::ClassMethods)
        end

        module ClassMethods
          def tunemygc_before_perform
          end

          def tunemygc_after_perform
          end
        end
      end
    end
  end
end
