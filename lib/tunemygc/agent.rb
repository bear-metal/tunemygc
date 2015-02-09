# encoding: utf-8

require "tunemygc/tunemygc_ext"
require "tunemygc/interposer"
require "tunemygc/snapshotter"
require "logger"

module TuneMyGc
  MUTEX = Mutex.new

  attr_accessor :logger, :interposer, :snapshotter

  def snapshot(stage, timestamp = nil, meta = nil)
    snapshotter.take(stage, timestamp, meta)
  end

  def raw_snapshot(snapshot)
    snapshotter.take_raw(snapshot)
  end

  def log(message)
    logger.info "[TuneMyGC] #{message}"
  end

  def spy
    ENV['RUBY_GC_SPY'] || :ActionController
  end

  def reccommendations
    MUTEX.synchronize do
      require "tunemygc/syncer"
      syncer = TuneMyGc::Syncer.new
      config = syncer.sync(snapshotter)
      require "tunemygc/configurator"
      TuneMyGc::Configurator.new(config).configure
    end
  rescue Exception => e
    log "Config reccommendation error (#{e.message})"
  end

  extend self

  MUTEX.synchronize do
    self.logger = Logger.new($stdout)
    self.interposer = TuneMyGc::Interposer.new
    self.snapshotter = TuneMyGc::Snapshotter.new
  end
end