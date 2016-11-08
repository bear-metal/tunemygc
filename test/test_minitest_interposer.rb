# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class MinitestSandboxTest < MiniTest::Unit::TestCase
  def setup
    @value = 123
  end

  def test_minitest_spy
    assert_equal 123, @value
  end
end

class TestMinitestInterposer < TuneMyGcInterposerTestCase

  def test_init
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:Minitest])
    interposer = TuneMyGc.interposer
    assert !interposer.installed
  end

  def test_install_uninstall
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:Minitest])
    interposer = TuneMyGc.interposer
    interposer.install
    interposer.on_initialized
    assert interposer.installed
    assert_nil interposer.install

    interposer.uninstall
  end

  def test_gc_hooks
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:Minitest])
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    GC.start(full_mark: true, immediate_sweep: false)
    GC.start(full_mark: true, immediate_sweep: true)

    stages = []

    while !TuneMyGc.snapshotter.empty?
      stages << TuneMyGc.snapshotter.deq
    end

    # Account for incremental GC on 2.2
    cycles = [:GC_CYCLE_STARTED, :GC_CYCLE_ENTERED]

    assert stages.any?{|s| cycles.include?(s[3]) }

    interposer.uninstall
  end

  def test_tests_limit
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:Minitest])
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    ENV["RUBY_GC_TUNE"] = "2"

    run_tunemygc_test
    run_tunemygc_test
    
    stages = []

    while !TuneMyGc.snapshotter.empty?
      stages << TuneMyGc.snapshotter.deq
    end

    cycles = [:PROCESSING_STARTED]

    assert stages.any?{|s| cycles.include?(s[3]) }

    interposer.uninstall
  ensure
    ENV["RUBY_GC_TUNE"] = "1"
  end

  def run_tunemygc_test
    MinitestSandboxTest.new("test_minitest_spy").run
  end
end
