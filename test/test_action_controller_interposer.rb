# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestActionControllerInterposer < TuneMyGcTestCase
  def setup
    TuneMyGc.interposer.uninstall
  end

  def test_init
    interposer = TuneMyGc.interposer
    assert !interposer.installed
    assert_equal [], interposer.spy.subscriptions
  end

  def test_install_uninstall
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    assert_equal 2, interposer.spy.subscriptions.size
    assert interposer.installed
    assert_nil interposer.install

    interposer.uninstall
    assert_equal [], interposer.spy.subscriptions
  end

  def test_gc_hooks
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
    assert_equal [], interposer.spy.subscriptions
  end

  def test_requests_limit
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    assert_equal 2, interposer.spy.subscriptions.size

    ENV["RUBY_GC_TUNE_REQUESTS"] = "2"

    process_tunemygc_request
    assert_equal 2, interposer.spy.subscriptions.size
    process_tunemygc_request
    assert_equal 0, interposer.spy.subscriptions.size

    stages = []

    while !TuneMyGc.snapshotter.empty?
      stages << TuneMyGc.snapshotter.deq
    end

    cycles = [:REQUEST_PROCESSING_STARTED]

    assert stages.any?{|s| cycles.include?(s[3]) }

    interposer.uninstall
  ensure
    ENV.delete("RUBY_GC_TUNE_REQUESTS")
  end
end