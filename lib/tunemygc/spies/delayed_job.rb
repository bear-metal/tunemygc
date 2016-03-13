# encoding: utf-8

require 'delayed_job'

module Delayed
  module Plugins
    class TuneMyGcPlugin < Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, *args, &block|
          TuneMyGc.processing_started
          block.call(job, *args)
          TuneMyGc.processing_ended
        end
      end
    end
  end
end

module TuneMyGc
  module Spies
    class DelayedJob < TuneMyGc::Spies::Base
      def install
        Delayed::Worker.plugins << Delayed::Plugins::TuneMyGcPlugin
        TuneMyGc.log "hooked: delayed_job"
      end

      def uninstall
        Delayed::Worker.plugins.delete(Delayed::Plugins::TuneMyGcPlugin)
        TuneMyGc.log "uninstalled delayed_job spy"
      end
    end
  end
end