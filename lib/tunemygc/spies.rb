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

    def self.id
      @spies.key(current)
    end

    def self.current
      if ENV['RUBY_GC_SPY']
        @spies[ENV['RUBY_GC_SPY']] || raise(NotImplementedError, "TuneMyGC spy #{ENV['RUBY_GC_SPY']} not supported. Valid spies are #{@spies.keys}")
      else
        TuneMyGc.rails? ? 'ActionController' : 'Manual'
      end
    end
  end
end