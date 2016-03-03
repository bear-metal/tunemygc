# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestKamikaze < MiniTest::Unit::TestCase
  def test_kamikaze
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
   TuneMyGc.stubs(:count_objects).returns({"TOTAL":172414,"FREE":85621,"T_OBJECT":4602,"T_CLASS":2521,"T_MODULE":287,"T_FLOAT":14,"T_STRING":43165,"T_REGEXP":996,"T_ARRAY":15116,"T_HASH":1737,"T_STRUCT":122,"T_BIGNUM":4,"T_FILE":3,"T_DATA":10450,"T_MATCH":8,"T_COMPLEX":1,"T_RATIONAL":59,"T_SYMBOL":57,"T_NODE":7340,"T_ICLASS":311,"memsize":22896062})
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(syncer.environment(snapshots))},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null,70201748333020]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 200, :body => "", :headers => {})
    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      TuneMyGc.interposer.kamikaze
    end
    sleep 1
    assert_match(/kamikaze\: synching \d GC sample snapshots ahead of time \(usually only on process exit\)/, out)
    assert_match(/Syncing \d snapshots/, out)
  end
end