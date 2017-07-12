# encoding: utf-8

require "tunemygc/tunemygc_ext"
require "tunemygc/interposer"
require "tunemygc/snapshotter"
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

  def terminated
    snapshot(:TERMINATED, count_objects)
  end

  def count_objects
    ObjectSpace.count_objects.merge(:memsize => ObjectSpace.memsize_of_all)
  end

  def snapshot(stage, meta = nil)
    snapshotter.take(stage, meta)
  end

  def raw_snapshot(snapshot)
    snapshotter.take_raw(snapshot)
  end

  def log(message)
    puts "[tunemygc, ppid: #{Process.ppid}, pid: #{Process.pid}] #{message}"
  end

  def spy_ids
    TuneMyGc::Spies.ids
  end

  def spies
    TuneMyGc::Spies.current
  end

  def recommendations
  # no op
  end

  extend self

  MUTEX.synchronize do
    self.interposer = TuneMyGc::Interposer.new
    self.snapshotter = TuneMyGc::Snapshotter.new
  end
end
