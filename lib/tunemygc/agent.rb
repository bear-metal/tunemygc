# encoding: utf-8

require "tunemygc/tunemygc_ext"
require "tunemygc/interposer"
require "tunemygc/snapshotter"
require "logger"
require "objspace"

module TuneMyGc
  MUTEX = Mutex.new

  attr_accessor :logger, :interposer, :snapshotter

  def booted
    TuneMyGc.interposer.install
  end

  def processing_started(meta = nil)
    snapshot(:PROCESSING_STARTED, meta)
  end

  def processing_ended(meta = nil)
    snapshot(:PROCESSING_ENDED, meta)
    interposer.check_uninstall
  end

  def snapshot(stage, meta = nil)
    snapshotter.take(stage, meta)
  end

  def raw_snapshot(snapshot)
    snapshotter.take_raw(snapshot)
  end

  def log(message)
    logger.info "[tunemygc, pid: #{Process.pid}] #{message}"
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
    log "Config recommendation error (#{e.message})"
  end

  extend self

  MUTEX.synchronize do
    self.logger = Logger.new($stdout)
    self.interposer = TuneMyGc::Interposer.new
    self.snapshotter = TuneMyGc::Snapshotter.new
  end
end
