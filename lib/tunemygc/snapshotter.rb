# encoding: utf-8

module TuneMyGc
  class Snapshotter
    MAX_SAMPLES = 1000

    attr_reader :buffer

    def initialize(buf = [])
      @buffer = buf
    end

    def take(stage, meta = nil)
      _buffer([TuneMyGc.walltime, stage, GC.stat, GC.latest_gc_info, meta])
    end

    # low level interface, for tests
    def take_raw(snapshot)
      _buffer(snapshot)
    end

    def clear
      @buffer.clear
    end

    def size
      @buffer.size
    end

    def debug
      TuneMyGc.log "=== Snapshots ==="
      buffer.each{|l| TuneMyGc.log(l) }
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