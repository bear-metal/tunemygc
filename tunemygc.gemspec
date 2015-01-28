# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tunemygc/version'

Gem::Specification.new do |s|
  s.name = "tunemygc"
  s.version = TuneMyGc::VERSION
  s.summary = "TuneMyGC - optimal MRI Ruby 2.1+ Garbage Collection"
  s.description = "Agent for the GC tuning webservice https://www.tunemygc.com - optimal settings for throughput and memory usage of Rails applications"
  s.authors = ["Bear Metal OÜ"]
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
  s.post_install_message <<-eos
  [TuneMyGC] Getting started:

  Run this setup command from your application root to register your application with the `https://tunemygc.com` service:

  bundle exec tunemygc -r your@email.address

  You should get back a token reference to identify this Rails app:

  Application registered. Use RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d32 in your environment.

  The sample your Rails app for tuning:

  RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d32 RUBY_GC_TUNE=1 bundle exec rails s

  We require a valid email address as a canonical reference for tuner tokens for your applications.

  Happy hacking,
  - the Bear Metal cubs
eos

  s.add_dependency('activesupport')
  s.add_dependency('certified')
  s.add_development_dependency('rake')
  s.add_development_dependency('rake-compiler', '~> 0.9.3')
  s.add_development_dependency('webmock')
end