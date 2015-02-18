# encoding: utf-8

module TuneMyGc
  module Spies
    class Manual
      def install
        TuneMyGc.log "hooked: manual"
      end

      def uninstall
        TuneMyGc.log "uninstalled manual spy"
      end

      def check_uninstall
      end
    end
  end
end