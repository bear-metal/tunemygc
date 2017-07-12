# encoding: utf-8

require 'thread'

module TuneMyGc
  class Snapshotter
    UNITS_OF_WORK = /PROCESSING_STARTED|PROCESSING_ENDED/
    TERMINATED = /TERMINATED/
    MAX_SAMPLES = (ENV['RUBY_GC_MAX_SAMPLES'] ? Integer(ENV['RUBY_GC_MAX_SAMPLES']) : 50000)

    attr_reader :buffer
    attr_accessor :unit_of_work, :reducer, :consumer
    attr_reader :stat_keys

    def initialize(buf = Queue.new)
      @buffer = buf
      @unit_of_work = false
      @stat_keys = GC.stat.keys
      @reducer = nil
      @consumer = nil
    end

    def take(stage, meta = nil)
      _buffer([TuneMyGc.walltime, TuneMyGc.peak_rss, TuneMyGc.current_rss, stage, GC.stat.values_at(*stat_keys), GC.latest_gc_info, meta, thread_id])
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
    def thread_id
      if Thread.current != Thread.main
        Thread.current.object_id
      end
    end

    def _buffer(snapshot)
      return consumer.call(snapshot) if consumer

      if reducer && size >= MAX_SAMPLES
        reducer.call(self)
      end

      if snapshot[3] =~ TERMINATED || size < MAX_SAMPLES
        unless self.unit_of_work
          self.unit_of_work = true if snapshot[3] =~ UNITS_OF_WORK
        end
        @buffer << snapshot
      else
        TuneMyGc.log "Discarding snapshot #{snapshot.inspect} (max samples threshold of #{MAX_SAMPLES} reached)"
      end
    end
  end
end