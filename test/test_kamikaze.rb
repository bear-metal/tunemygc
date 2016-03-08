# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestKamikaze < MiniTest::Unit::TestCase
  def test_kamikaze
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    TuneMyGc.stubs(:terminated).returns(Fixtures::STAGE_TERMINATED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(syncer.environment(snapshots))},[1457436980.906017,42086400,42086400,\"TERMINATED\",[25,423,424,0,172410,170706,1704,0,88657,9006,423,0,423,0,793852,623146,1211456,16777216,20,5,1013,1354,86740,113636,13091056,16777216],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false,\"state\":\"sweeping\"},{\"TOTAL\":172414,\"FREE\":85621,\"T_OBJECT\":4602,\"T_CLASS\":2521,\"T_MODULE\":287,\"T_FLOAT\":14,\"T_STRING\":43165,\"T_REGEXP\":996,\"T_ARRAY\":15116,\"T_HASH\":1737,\"T_STRUCT\":122,\"T_BIGNUM\":4,\"T_FILE\":3,\"T_DATA\":10450,\"T_MATCH\":8,\"T_COMPLEX\":1,\"T_RATIONAL\":59,\"T_SYMBOL\":57,\"T_NODE\":7340,\"T_ICLASS\":311,\"memsize\":22896062},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).to_return(:status => 200, :body => "", :headers => {})
    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      TuneMyGc.interposer.kamikaze.join(1)
    end
    assert_match(/kamikaze\: synching \d GC sample snapshots ahead of time \(usually only on process exit\)/, out)
    assert_match(/Syncing \d snapshots/, out)
  end
end