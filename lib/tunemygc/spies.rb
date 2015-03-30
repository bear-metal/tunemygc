# encoding: utf-8

module TuneMyGc
  module Spies
    def self.spy(s, file)
      autoload s, "tunemygc/spies/#{file}"
      (@spies ||= {})[file] = s.to_s
    end

    spy :Base, 'base'
    spy :ActionController, 'action_controller'
    spy :Minitest, 'minitest'
    spy :ActiveJob, 'active_job'
    spy :Manual, 'manual'
    spy :Rspec, 'rspec'
    spy :QueJob, 'que_job'

    def self.ids
      current.map do |spy|
        @spies.key(spy)
      end.join(',')
    end

    def self.current
      if ENV['RUBY_GC_SPY'] && ENV['RUBY_GC_SPY'] != ""
        ENV['RUBY_GC_SPY'].split(",").map do |spy|
          @spies[spy] || raise(NotImplementedError, "TuneMyGC spy #{spy} not supported. Valid spies are #{@spies.keys}")
        end
      else
        [(TuneMyGc.rails? ? 'ActionController' : 'Manual')]
      end
    end
  end
end
