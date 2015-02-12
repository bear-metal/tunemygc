# encoding: utf-8

module TuneMyGc
  module Spies
    autoload :ActionController, 'tunemygc/spies/action_controller'
    autoload :Minitest, 'tunemygc/spies/minitest'
    autoload :ActiveJob, 'tunemygc/spies/active_job'
  end
end