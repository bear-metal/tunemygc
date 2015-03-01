# encoding: utf-8

module TuneMyGc
  module Spies
    class Base
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