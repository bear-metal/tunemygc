# encoding: utf-8

module TuneMyGc
  module Spies
    class Base
      def initialize
        @processed = 0
        @limit = nil
      end

      def install
        raise NotImplementedError
      end

      def uninstall
        raise NotImplementedError
      end

      def check_uninstall
        raise NotImplementedError
      end
    end
  end
end