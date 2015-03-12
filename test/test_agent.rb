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
    assert_equal 'ActionController', TuneMyGc.spy
    ENV['RUBY_GC_SPY'] = "minitest"
    assert_equal 'Minitest', TuneMyGc.spy
    assert_equal 'minitest', TuneMyGc.spy_id
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