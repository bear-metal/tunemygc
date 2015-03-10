# encoding: utf-8

require 'active_job'

module TuneMyGc
  module Spies
    class ActiveJob < TuneMyGc::Spies::Base
      def install
        ::ActiveJob::Base.__send__(:include, hooks_module)
        TuneMyGc.log "hooked: active_job"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        ::ActiveJob::Base.__send__(:include, disabled_hooks_module)
        TuneMyGc.log "uninstalled active_job spy"
      end

      def check_uninstall
        if ENV["RUBY_GC_TUNE_JOBS"]
          @limit ||= Integer(ENV["RUBY_GC_TUNE_JOBS"])
          @processed += 1
          if @processed == @limit
            uninstall
            TuneMyGc.log "kamikaze after #{@processed} of #{@limit} jobs"
          end
        end
      end

      def hooks_module
        Module.new do
          def self.included(base)
            base.around_perform :tunemygc_perform_job
          end

          def tunemygc_perform_job(*args)
            tunemygc_before_perform
            yield
            tunemygc_after_perform
          end

          def tunemygc_before_perform
            TuneMyGc.processing_started
          end

          def tunemygc_after_perform
            TuneMyGc.processing_ended
          end
        end
      end

      def disabled_hooks_module
        Module.new do
          def tunemygc_before_perform
          end

          def tunemygc_after_perform
          end
        end
      end
    end
  end
end