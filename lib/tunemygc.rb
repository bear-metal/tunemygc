# encoding: utf-8

require "tunemygc/version" unless defined? TuneMyGc::VERSION

module TuneMyGc
  HOST = (ENV['RUBY_GC_TUNE_HOST'] || "tunemygc.com:443").freeze
  HEADERS = { "Content-Type" => "application/json",
              "Accept" => "application/json",
              "User-Agent" => "TuneMyGC #{TuneMyGc::VERSION}"}.freeze
end

if ENV["RUBY_GC_TUNE"] && defined?(Rails) && Rails.version >= "4.0"
  require 'tunemygc/railtie'
else
  puts "[TuneMyGC] not enabled"
end
