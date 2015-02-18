# encoding: utf-8

module TuneMyGc
  module Spies
    def self.spy(s)
      autoload s, "tunemygc/spies/#{s.to_s.underscore}"
      (@spies ||= []) << s.to_s
    end

    spy :ActionController
    spy :Minitest
    spy :ActiveJob
    spy :Manual

    def self.current
      s = if ENV['RUBY_GC_SPY']
        ENV['RUBY_GC_SPY'].classify
      else
        TuneMyGc.rails? ? 'ActionController' : 'Manual'
      end
      unless @spies.include?(s)
        raise NotImplementedError, "TuneMyGC spy #{s.underscore.inspect} not supported. Valid spies are #{@spies.map(&:underscore)}"
      end
      s
    end
  end
end