# encoding: utf-8

require 'thread'

module TuneMyGc
  class Snapshotter
    MAX_SAMPLES = 1000

    attr_reader :buffer

    def initialize(buf = Queue.new)
      @buffer = buf
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
        @buffer << snapshot
      else
        TuneMyGc.log "Discarding snapshot #{snapshot.inspect} (max samples threshold of #{MAX_SAMPLES} reached)"
      end
    end
  end
end