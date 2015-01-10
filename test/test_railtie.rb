# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestRailtie < TuneMyGcTestCase
  def test_init
    out, err = capture_io do
      Rails.logger = Logger.new($stdout)
      TuneMyGc::Railtie.run_initializers
      sleep 1
    end
    assert_equal Rails.logger, TuneMyGc.logger
    assert_match(/interposing/, out)
    assert_match(/after_initialize/, out)
    assert_match(/at_exit/, out)
    assert_match(/interposed/, out)
  ensure
    TuneMyGc.logger = Logger.new($stdout)
    TuneMyGc.interposer.uninstall
  end
end