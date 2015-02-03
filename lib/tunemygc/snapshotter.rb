# encoding: utf-8

require 'thread'

module TuneMyGc
  class Snapshotter
    UNITS_OF_WORK = /REQUEST_PROCESSING_STARTED|REQUEST_PROCESSING_ENDED/
    MAX_SAMPLES = 1000

    attr_reader :buffer, :unit_of_work

    def initialize(buf = Queue.new)
      @buffer = buf
      @unit_of_work = false
    end

    def take(stage, timestamp = nil, meta = nil)
      _buffer([(timestamp || TuneMyGc.walltime), TuneMyGc.peak_rss, TuneMyGc.current_rss, stage, GC.stat, GC.latest_gc_info, meta])
    end

    # low level interface, for tests and GC callback
    def take_raw(snapshot)
      _buffer(snapshot)
    end

    def clear
      @buffer.clear
    end

    def size
      @buffer.size
    end

    def deq
      @buffer.deq
    end

    def empty?
      @buffer.empty?
    end

    private
    def _buffer(snapshot)
      if size < MAX_SAMPLES
        @unit_if_work = true if snapshot[3] =~ UNITS_OF_WORK
        @buffer << snapshot
      else
        TuneMyGc.log "Discarding snapshot #{snapshot.inspect} (max samples threshold of #{MAX_SAMPLES} reached)"
      end
    end
  end
end