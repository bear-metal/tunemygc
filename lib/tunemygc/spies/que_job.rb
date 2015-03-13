# encoding: utf-8

require 'que'

module TuneMyGc
  module Spies
    class QueJob < TuneMyGc::Spies::Base
      def install
        ::Que::Job.__send__(:prepend, TuneMyGc::Spies::QueJob::Hooks)
        TuneMyGc.log "hooked: que_job"
      end

      def uninstall
        TuneMyGc.uninstall_gc_tracepoint
        TuneMyGc.log "uninstalled GC tracepoint"
        ::Que::Job.__send__(:include, TuneMyGc::Spies::QueJob::DisabledHooks)
        TuneMyGc.log "uninstalled que_job spy"
      end

      module Hooks
        def run(*args)
          self.class.tunemygc_before_run
          super
        ensure
          self.class.tunemygc_after_run
        end

        def self.prepended(klass)
          klass.extend(TuneMyGc::Spies::QueJob::Hooks::ClassMethods)
        end

        module ClassMethods
          def tunemygc_before_run
            TuneMyGc.processing_started
          end

          def tunemygc_after_run
            TuneMyGc.processing_ended
          end
        end
      end

      module DisabledHooks
        def self.included(klass)
          klass.extend(TuneMyGc::Spies::QueJob::DisabledHooks::ClassMethods)
        end

        module ClassMethods
          def tunemygc_before_run
          end

          def tunemygc_after_run
          end
        end
      end
    end
  end
end
