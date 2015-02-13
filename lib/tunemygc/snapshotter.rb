# encoding: utf-8

require 'thread'

module TuneMyGc
  class Snapshotter
    UNITS_OF_WORK = /PROCESSING_STARTED|PROCESSING_ENDED/
    TERMINATED = /TERMINATED/
    MAX_SAMPLES = (ENV['RUBY_GC_MAX_SAMPLES'] ? Integer(ENV['RUBY_GC_MAX_SAMPLES']) : 2000)

    attr_reader :buffer
    attr_accessor :unit_of_work
    attr_reader :stat_keys

    def initialize(buf = Queue.new)
      @buffer = buf
      @unit_of_work = false
      @stat_keys = GC.stat.keys
    end

    def take(stage, meta = nil)
      _buffer([TuneMyGc.walltime, TuneMyGc.peak_rss, TuneMyGc.current_rss, stage, GC.stat.values_at(*stat_keys), GC.latest_gc_info, meta])
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
      if snapshot[3] =~ TERMINATED || size < MAX_SAMPLES
        self.unit_of_work = true if snapshot[3] =~ UNITS_OF_WORK
        @buffer << snapshot
      else
        TuneMyGc.log "Discarding snapshot #{snapshot.inspect} (max samples threshold of #{MAX_SAMPLES} reached)"
      end
    end
  end
end