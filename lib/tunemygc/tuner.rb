# encoding: utf-8

module TuneMyGc
  class Tuner
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def configure
      if Hash === config && !config.empty?
        log "==== Recommended GC config (#{config.delete("callback")}) ===="
        memory = config.delete("Memory")
        log "== Optimize for memory"
        memory.each do |var,val|
          log "#{var}=#{val}"
        end
        speed = config.delete("Speed")
        log "== Optimize for speed"
        speed.each do |var,val|
          log "#{var}=#{val}"
        end
      end
    end
  end
end