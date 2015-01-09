# encoding: utf-8

require 'rubygems' unless defined?(Gem)
require 'rake' unless defined?(Rake)

require 'rake/extensiontask'
require 'rake/testtask'

Rake::ExtensionTask.new('tunemygc') do |ext|
  ext.name = 'tunemygc_ext'
  ext.ext_dir = 'ext/tunemygc'
  ext.lib_dir = "lib/tunemygc"
  CLEAN.include 'lib/**/tunemygc_ext.*'
end

desc 'Run tunemygc tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = "test/**/test_*.rb"
  t.verbose = true
  t.warning = true
end

namespace :debug do
  desc "Run the test suite under gdb"
  task :gdb do
    system "gdb --args ruby rake"
  end
end

task :test => :compile
task :default => :test