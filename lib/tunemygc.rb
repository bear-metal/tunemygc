# encoding: utf-8

tunemygc_min_ruby_version = "2.1.0"

if RUBY_VERSION >= tunemygc_min_ruby_version
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
else
  puts "[TuneMyGC] requires a Ruby version #{tunemygc_min_ruby_version} or newer"
end