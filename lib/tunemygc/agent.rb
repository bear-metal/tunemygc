# encoding: utf-8

require "tunemygc/tunemygc_ext"
require "tunemygc/version" unless defined? TuneMyGc::VERSION
require "tunemygc/interposer"
require "tunemygc/snapshotter"

module TuneMyGc
  MUTEX = Mutex.new

  attr_accessor :logger, :interposer, :snapshotter

  def snapshot(stage, meta = nil)
    MUTEX.synchronize do
      snapshotter.take(stage, meta)
    end
  end

  def raw_snapshot(snapshot)
    MUTEX.synchronize do
      snapshotter.take_raw(snapshot)
    end
  end

  def log(message)
    MUTEX.synchronize do
      if logger
        logger.info "[TuneMyGC] #{message}"
      else
        puts "[TuneMyGC] #{message}"
      end
    end
  end

  def reccommendations
    snapshotter.debug if ENV["RUBY_GC_TUNE_DEBUG"]
    require "tunemygc/syncer"
    syncer = TuneMyGc::Syncer.new
    config = syncer.sync(snapshotter)
    if Hash === config && !config.empty?
      log "==== Recommended GC config ===="
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

  extend self

  MUTEX.synchronize do
    self.interposer = TuneMyGc::Interposer.new
    self.snapshotter = TuneMyGc::Snapshotter.new
  end
end