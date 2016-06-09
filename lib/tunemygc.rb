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

  def self.run_silently?
    !ENV['RUBY_GC_TUNE_VERBOSE'].nil? && ENV['RUBY_GC_TUNE_VERBOSE'].to_i == 0
  end

  def self.enabled?
    ENV["RUBY_GC_TUNE"] && ENV["RUBY_GC_TUNE"] != ""
  end
end

if TuneMyGc.enabled?
  if TuneMyGc.rails?
    puts "[tunemygc] Rails detected, loading railtie"
    require 'tunemygc/railtie'
  else
    puts "[tunemygc] Rails not detected, loading minimal agent"
    require 'tunemygc/agent'
    TuneMyGc.booted
  end
else
  STDERR.puts "[tunemygc] not enabled" unless TuneMyGc.run_silently?
end
