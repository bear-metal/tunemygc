# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestAgent < TuneMyGcTestCase
  def test_interposer
    assert_instance_of TuneMyGc::Interposer, TuneMyGc.interposer
  end

  def test_snapshotter
    assert_instance_of TuneMyGc::Snapshotter, TuneMyGc.snapshotter
  end

  def test_spy
    assert_equal ['ActionController'], TuneMyGc.spies
    ENV['RUBY_GC_SPY'] = "minitest"
    assert_equal ['Minitest'], TuneMyGc.spies
    assert_equal 'minitest', TuneMyGc.spy_ids
    ENV['RUBY_GC_SPY'] = "action_controller,active_job"
    assert_equal ['ActionController','ActiveJob'], TuneMyGc.spies
    assert_equal 'action_controller,active_job', TuneMyGc.spy_ids
  ensure
    ENV.delete('RUBY_GC_SPY')
  end

  def test_log
    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      TuneMyGc.log 'test'
    end
    assert_match(/test/, out)
  end
end