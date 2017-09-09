# encoding: utf-8

require 'minitest'

module TuneMyGc
  module Spies
    class Minitest < TuneMyGc::Spies::Base
      def install
        MiniTest::Test.__send__(:include, hooks_module)
        TuneMyGc.log "hooked: minitest"
      end

      def uninstall
        MiniTest::Test.__send__(:include, disabled_hooks_module)
        TuneMyGc.log "uninstalled minitest spy"
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
            TuneMyGc.processing_started
          end

          def tunemygc_after_teardown
            TuneMyGc.processing_ended
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