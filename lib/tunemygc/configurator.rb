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
      File.open(path, "w") do |f|
        TuneMyGc.log "== start #{strategy} config =="
        config.delete(strategy).each do |var,val|
          TuneMyGc.log "#{var}=#{val}"
          f.write "#{var}=#{val}\n"
        end
        TuneMyGc.log "== end #{strategy} config =="
      end
      path
    rescue Exception => e
      TuneMyGc.log "Failed to write #{strategy} config (#{e.message})"
    end
  end
end