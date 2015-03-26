# encoding: utf-8

require "tunemygc/tunemygc_ext"
require "tunemygc/interposer"
require "tunemygc/snapshotter"
require "logger"

module TuneMyGc
  MUTEX = Mutex.new

  attr_accessor :logger, :interposer, :snapshotter

  def booted
    TuneMyGc.interposer.install
  end

  def processing_started
    snapshot(:PROCESSING_STARTED)
  end

  def processing_ended
    snapshot(:PROCESSING_ENDED)
    interposer.check_uninstall
  end

  def snapshot(stage, meta = nil)
    snapshotter.take(stage, meta)
  end

  def raw_snapshot(snapshot)
    snapshotter.take_raw(snapshot)
  end

  def log(message)
    logger.info "[TuneMyGC, pid: #{Process.pid}] #{message}"
  end

  def spy_ids
    TuneMyGc::Spies.ids
  end

  def spies
    TuneMyGc::Spies.current
  end

  def reccommendations
    MUTEX.synchronize do
      require "tunemygc/syncer"
      syncer = TuneMyGc::Syncer.new
      config = syncer.sync(snapshotter)
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