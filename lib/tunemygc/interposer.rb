# encoding: utf-8

require 'tunemygc/spies'

module TuneMyGc
  class Interposer
    attr_reader :spies
    attr_accessor :installed

    def initialize(spies = TuneMyGc.spies)
      reset
      @spies = spies.map{|s| TuneMyGc::Spies.const_get(s).new }
    end

    def spy
      @spies.first
    end

    def on_initialized
      GC.start(full_mark: true, :immediate_sweep => true)
      TuneMyGc.install_gc_tracepoint
      TuneMyGc.log "hooked: GC tracepoints"
      TuneMyGc.snapshot(:BOOTED, ObjectSpace.count_objects.merge(:memsize => ObjectSpace.memsize_of_all))
      TuneMyGc.interposer.spies.each{|s| s.install }
    end

    def install
      return if @installed
      TuneMyGc.log "interposing"
      if TuneMyGc.rails?
        require 'active_support'
        ActiveSupport.on_load(:after_initialize) do
          TuneMyGc.interposer.on_initialized
        end
      else
        TuneMyGc.interposer.on_initialized
      end
      TuneMyGc.log "hooked: after_initialize"

      at_exit do
        if @installed
          TuneMyGc.log "at_exit"
          @spies.each{|s| s.uninstall }
          TuneMyGc.snapshot(:TERMINATED, ObjectSpace.count_objects.merge(:memsize => ObjectSpace.memsize_of_all))
          TuneMyGc.recommendations
        end
      end
      TuneMyGc.log "hooked: at_exit"
      @installed = true
      TuneMyGc.log "interposed"
    end

    def check_uninstall
      @spies.each{|s| s.check_uninstall }
    end

    def uninstall
      TuneMyGc.uninstall_gc_tracepoint
      TuneMyGc.log "uninstalled GC tracepoint"
      @spies.each{|s| s.uninstall }
      reset
    end

    private
    def reset
      @installed = false
    end
  end
end
