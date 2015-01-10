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
        TuneMyGc.log "== Wrote #{write_env("Memory")}"
        TuneMyGc.log "== Wrote #{write_env("Speed")}"
      end
    end

    private
    def write_env(strategy)
      path = File.join(Rails.root, "tunemygc-#{strategy.downcase}.env")
      File.open(path) do |f|
        config.delete(strategy).each do |var,val|
          f.write "#{var}=#{val}"
        end
      end
      path
    end
  end
end