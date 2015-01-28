# encoding: utf-8

require 'tunemygc/subscriber'

module TuneMyGc
  class StartRequestSubscriber < Subscriber
    def start(name, id, payload)
      TuneMyGc.snapshot(:REQUEST_PROCESSING_STARTED)
    end
  end

  class EndRequestSubscriber < Subscriber
    def finish(name, id, payload)
      TuneMyGc.snapshot(:REQUEST_PROCESSING_ENDED)
      TuneMyGc.interposer.check_uninstall_request_processing
    end
  end
end