# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')
require 'delayed_job'

Delayed::Worker.delay_jobs = false

NewsletterJob = Struct.new(:text, :emails) do
  def perform
  end
end

class TestDelayedJobInterposer < TuneMyGcTestCase
  def setup
    TuneMyGc.interposer.uninstall
  end

  def teardown
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:ActionController])
  end

  def test_init
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:DelayedJob])
    interposer = TuneMyGc.interposer
    assert !interposer.installed
  end

  def test_install_uninstall
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:DelayedJob])
    interposer = TuneMyGc.interposer
    interposer.install
    interposer.on_initialized
    assert interposer.installed
    assert_nil interposer.install

    interposer.uninstall
  end

  def test_gc_hooks
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:DelayedJob])
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
    TuneMyGc.interposer = TuneMyGc::Interposer.new([:DelayedJob])
    interposer = TuneMyGc.interposer
    interposer.install
    TuneMyGc.interposer.on_initialized

    ENV["RUBY_GC_TUNE"] = "2"

    require 'delayed_job_test_backend'
    Delayed.const_set(:Job, Delayed::Backend::Test::Job)
    worker = Delayed::Worker.new(:max_priority => nil, :min_priority => nil, :quiet => true)
    worker.work_off

    run_newsletter_job
    run_newsletter_job

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

  def run_newsletter_job
    Delayed::Job.enqueue NewsletterJob.new("test", %w(lourens@bearmetal.eu))
  end
end