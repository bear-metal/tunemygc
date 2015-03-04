# encoding: utf-8

module TuneMyGc
  class Configurator
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def configure
      if Hash === config && !config.empty?
        TuneMyGc.log "==== Recommended GC configs for #{TuneMyGCc::Spies.current}: #{config.delete("report")}"
        write_env("Speed")
      end
    end

    private
    def write_env(strategy)
      config.delete(strategy).each do |var,val|
        TuneMyGc.log "export #{var}=#{val}"
      end
    end
  end
end