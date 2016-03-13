# encoding: utf-8

begin
  require 'rspec'
rescue LoadError
  require 'rspec/core'
end

module TuneMyGc
  module Spies
    class Rspec < TuneMyGc::Spies::Base
      def install
        RSpec::Core.__send__(:include, hooks_module)
        TuneMyGc.log "hooked: rspec"
      end

      def uninstall
        RSpec::Core.__send__(:include, disabled_hooks_module)
        TuneMyGc.log "uninstalled rspec spy"
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
