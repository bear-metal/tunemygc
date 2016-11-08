# encoding: utf-8

ENV['RUBY_GC_TOKEN'] = 'testapp'

require 'rails'
require 'tunemygc'
require "tunemygc/syncer"
require 'minitest/autorun'
require 'webmock/minitest'
require 'mocha/mini_test'

WebMock.disable_net_connect!

require File.join(File.dirname(__FILE__), 'fixtures')

class TuneMyGcTestCase < Minitest::Test

  def setup
    GC.stress = true if ENV['STRESS_GC'] == '1'
    store_current_threads
  end

  def teardown
    GC.stress = false if ENV['STRESS_GC'] == '1'
    cleanup_temporary_threads
  end

  def store_current_threads
    @original_threads = Thread.list
  end

  def cleanup_temporary_threads
    (Thread.list - @original_threads).each(&:join)
  end
end

class TuneMyGcInterposerTestCase < TuneMyGcTestCase
  def setup
    super
    interposer_setup
  end

  def teardown
    super # order matters: clean up threads first, then reset environment
    interposer_teardown
  end

  def interposer_setup
    TuneMyGc.interposer.uninstall

    # Force disable syncing because we want to capture the snapshots
    ENV["RUBY_GC_SYNC_NEVER"] = "1"
  end

  def interposer_teardown
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:ActionController])
    ENV["RUBY_GC_SYNC_NEVER"] = nil
  end
end
