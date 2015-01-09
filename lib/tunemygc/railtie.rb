# encoding: utf-8

require 'tunemygc/agent'
require 'rails/railtie'

module TuneMyGc
  class Railtie < Rails::Railtie
    initializer 'tunemygc' do
      TuneMyGc.logger = Rails.logger
      TuneMyGc.interposer.install
    end
  end
end