# encoding: utf-8

module TuneMyGc
  module Spies
    class Manual < TuneMyGc::Spies::Base
      def install
        TuneMyGc.log "hooked: manual"
      end

      def uninstall
        TuneMyGc.log "uninstalled manual spy"
      end
    end
  end
end