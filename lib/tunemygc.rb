# encoding: utf-8

require "tunemygc/version" unless defined? TuneMyGc::VERSION

module TuneMyGc
  HOST = (ENV['RUBY_GC_TUNE_HOST'] || "tunemygc.com:443").freeze
  HEADERS = { "Content-Type" => "application/json",
              "Accept" => "application/json",
              "User-Agent" => "TuneMyGC #{TuneMyGc::VERSION}"}.freeze

  def self.rails?
    defined?(Rails) && Rails.version >= "3.0"
  end

  def self.rails_version
    rails? ? Rails.version : "0.0"
  end
end

if ENV["RUBY_GC_TUNE"]
  if TuneMyGc.rails?
    puts "[TuneMyGC] Rails detected, loading railtie"
    require 'tunemygc/railtie'
  else
    puts "[TuneMyGC] Rails not detected, loading minimal agent"
    require 'tunemygc/agent'
    TuneMyGc.booted
  end
else
  puts "[TuneMyGC] not enabled"
end
