# encoding: utf-8

require 'active_support'
require 'tunemygc/spies/action_controller'

module TuneMyGc
  class Interposer
    attr_reader :spy
    attr_accessor :installed

    def initialize
      reset
    end

    def on_initialized
      GC.start(full_mark: true, :immediate_sweep => true)
      TuneMyGc.install_gc_tracepoint
      TuneMyGc.log "hooked: GC tracepoints"
      TuneMyGc.snapshot(:BOOTED)

      TuneMyGc.interposer.spy.install
    end

    def install
      return if @installed
      TuneMyGc.log "interposing"
      ActiveSupport.on_load(:after_initialize) do
        TuneMyGc.interposer.on_initialized
      end
      TuneMyGc.log "hooked: after_initialize"

      at_exit do
        if @installed
          TuneMyGc.log "at_exit"
          @spy.uninstall
          TuneMyGc.snapshot(:TERMINATED)
          TuneMyGc.reccommendations
        end
      end
      TuneMyGc.log "hooked: at_exit"
      @installed = true
      TuneMyGc.log "interposed"
    end

    def check_uninstall
      @spy.check_uninstall
    end

    def uninstall
      @spy.uninstall
      reset
    end

    private
    def reset
      @installed = false
      @spy = TuneMyGc::Spies::ActionController.new
    end
  end
end