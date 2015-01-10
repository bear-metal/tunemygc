# encoding: utf-8

tunemygc_min_ruby_version = "2.1.0"

if RUBY_VERSION >= tunemygc_min_ruby_version
  if ENV["RUBY_GC_TUNE"] && defined?(Rails) && Rails.version >= "4.0"
    require 'tunemygc/railtie'
  end
else
  puts "[TuneMyGC] requires a Ruby version #{tunemygc_min_ruby_version} or newer"
end
