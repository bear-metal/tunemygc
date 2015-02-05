# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestSyncer < TuneMyGcTestCase
  def test_uri
    syncer = TuneMyGc::Syncer.new
    assert_equal "tunemygc.com", syncer.uri.host
    assert_equal 443, syncer.uri.port
  end

  def test_client
    syncer = TuneMyGc::Syncer.new
    assert_instance_of Net::HTTP, syncer.client
  end

  def test_environment
    assert_equal 7, TuneMyGc::Syncer::ENVIRONMENT.size
  end

  def test_sync_valid_snapshot
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)

    stub_request(:get, "https://tunemygc.com/configs/xxxxxxx").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => ActiveSupport::JSON.encode({:Memory=>{:RUBY_GC_HEAP_INIT_SLOTS=>477268, :RUBY_GC_HEAP_FREE_SLOTS=>106607, :RUBY_GC_HEAP_GROWTH_FACTOR=>1.05, :RUBY_GC_HEAP_GROWTH_MAX_SLOTS=>10661, :RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=>1.05, :RUBY_GC_MALLOC_LIMIT=>2000000, :RUBY_GC_MALLOC_LIMIT_MAX=>4000000, :RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=>1.1, :RUBY_GC_OLDMALLOC_LIMIT=>2000000, :RUBY_GC_OLDMALLOC_LIMIT_MAX=>4000000, :RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=>1.05}, :Speed=>{:RUBY_GC_HEAP_INIT_SLOTS=>572722, :RUBY_GC_HEAP_FREE_SLOTS=>553800, :RUBY_GC_HEAP_GROWTH_FACTOR=>1.2, :RUBY_GC_HEAP_GROWTH_MAX_SLOTS=>83070, :RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=>2.0, :RUBY_GC_MALLOC_LIMIT=>64000000, :RUBY_GC_MALLOC_LIMIT_MAX=>128000000, :RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=>1.56, :RUBY_GC_OLDMALLOC_LIMIT=>64000000, :RUBY_GC_OLDMALLOC_LIMIT_MAX=>33554432, :RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=>1.32}}), :headers => {})

    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 200, :body => "https://www.tunemygc.com/configs/xxxxxxx", :headers => {})

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert syncer.sync(snapshots)
      #s = syncer.sync(snapshots)
      #assert s
    end
    assert_match(/Syncing 1 snapshots/, out)
  end

  def test_not_supported
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 501, :body => "", :headers => {})

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert_nil syncer.sync(snapshots)
    end
    assert_match(/Ruby version/, out)
    assert_match(/Rails version/, out)
    assert_match(/not supported/, out)
    assert_match(/Failed to sync 1 snapshots/, out)
  end

  def test_already_configured
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 412, :body => "", :headers => {})

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert_nil syncer.sync(snapshots)
    end
    assert_match(/The GC is already tuned by environment variables/, out)
    assert_match(/Failed to sync 1 snapshots/, out)
  end

  def test_bad_payload
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 400, :body => "snapshot timestamp", :headers => {})

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert_nil syncer.sync(snapshots)
    end
    assert_match(/Invalid payload/, out)
    assert_match(/snapshot timestamp/, out)
    assert_match(/Failed to sync 1 snapshots/, out)
  end

  def test_invalid_token
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 404, :body => "", :headers => {})

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert_nil syncer.sync(snapshots)
    end
    assert_match(/Invalid application token/, out)
  end

  def test_upgrade_required
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).
      to_return(:status => 426, :body => "2", :headers => {})

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert_nil syncer.sync(snapshots)
    end
    assert_match(/Agent version 2 required/, out)
    assert_match(/Failed to sync 1 snapshots/, out)
  end

  def test_sync_error
    syncer = TuneMyGc::Syncer.new
    snapshots = TuneMyGc::Snapshotter.new
    snapshots.take_raw(Fixtures::STAGE_BOOTED)
    stub_request(:post, "https://tunemygc.com/ruby").
      with(:body => "[#{ActiveSupport::JSON.encode(TuneMyGc::Syncer::ENVIRONMENT)},[1420152606.1162581,\"BOOTED\",[32,950,1519,569,385225,2014,0,101119,950,0,2184137,1798912,9665288,16777216,26,6,5145,6032,230164,301030,11715304,24159190],{\"major_by\":null,\"gc_by\":\"newobj\",\"have_finalizer\":false,\"immediate_sweep\":false},null]]",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>"TuneMyGC #{TuneMyGc::VERSION}"}).to_raise(IOError.new("dang"))

    out, err = capture_io do
      TuneMyGc.logger = Logger.new($stdout)
      assert_nil syncer.sync(snapshots)
    end
    assert_match(/Failed to sync 1 snapshots/, out)
    assert_match(/dang/, out)
  end
end