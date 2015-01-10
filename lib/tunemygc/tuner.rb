# encoding: utf-8

module TuneMyGc
  class Tuner
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def configure
      if Hash === config && !config.empty?
        TuneMyGc.log "==== Recommended GC config (#{config.delete("callback")}) ===="
        memory = config.delete("Memory")
        TuneMyGc.log "== Optimize for memory"
        memory.each do |var,val|
          TuneMyGc.log "#{var}=#{val}"
        end
        speed = config.delete("Speed")
        TuneMyGc.log "== Optimize for speed"
        speed.each do |var,val|
          TuneMyGc.log "#{var}=#{val}"
        end
      end
    end
  end
end