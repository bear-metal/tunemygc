# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tunemygc/version'

Gem::Specification.new do |s|
  s.name = "tunemygc"
  s.version = TuneMyGc::VERSION
  s.summary = "TuneMyGC - optimal MRI Ruby 2.1+ Garbage Collection"
  s.description = "Agent for the GC tuning webservice https://www.tunemygc.com - optimal settings for throughput and memory usage of Rails applications"
  s.authors = ["Bear Metal"]
  s.email = ["info@bearmetal.eu"]
  s.license = "MIT"
  s.homepage = "https://tunemygc.com"
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.extensions = "ext/tunemygc/extconf.rb"
  s.test_files = `git ls-files test`.split($/)
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.1.0'

  s.add_development_dependency('activesupport', '~> 4.1')
  s.add_development_dependency('rake', '~> 10.3')
  s.add_development_dependency('rake-compiler', '~> 0.9', '>= 0.9.5')
  s.add_development_dependency('webmock', '~> 1.2', '>= 1.2.0')
  s.add_development_dependency('activejob', '~> 4.2.0')
end