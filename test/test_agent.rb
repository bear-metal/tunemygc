# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestAgent < TuneMyGcTestCase
  def test_interposer
    assert_instance_of TuneMyGc::Interposer, TuneMyGc.interposer
  end

  def test_snapshotter
    assert_instance_of TuneMyGc::Snapshotter, TuneMyGc.snapshotter
  end

  def test_log
    out, err = capture_io do
      TuneMyGc.log 'test'
    end
    assert_match(/test/, out)
  end
end