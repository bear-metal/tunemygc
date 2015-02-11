# encoding: utf-8

require 'tunemygc/subscriber'

module TuneMyGc
  class StartRequestSubscriber < Subscriber
    def start(name, id, payload)
      TuneMyGc.snapshot(:PROCESSING_STARTED)
    end
  end

  class EndRequestSubscriber < Subscriber
    def finish(name, id, payload)
      TuneMyGc.snapshot(:PROCESSING_ENDED)
      TuneMyGc.interposer.check_uninstall
    end
  end
end