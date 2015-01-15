# encoding: utf-8

module TuneMyGc
  class Configurator
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def configure
      if Hash === config && !config.empty?
        TuneMyGc.log "==== Recommended GC configs from #{config.delete("callback")}"
        write_env("Memory")
        write_env("Speed")
      end
    end

    private
    def write_env(strategy)
      TuneMyGc.log "== start #{strategy.downcase} config =="
      config.delete(strategy).each do |var,val|
        TuneMyGc.log "#{var}=#{val}"
      end
      TuneMyGc.log "== end #{strategy.downcase} config =="
      strategy
    end
  end
end