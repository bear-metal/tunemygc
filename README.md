## [TuneMyGC](https://www.tunemygc.com) - optimal MRI Ruby 2.1+ Garbage Collection

[![Build Status](https://travis-ci.org/bear-metal/tunemygc.svg)](https://travis-ci.org/bear-metal/tunemygc)

The Ruby garbage collector has been flagged as the crux of Ruby performance and memory use for a long time. It has improved a lot over the last years, but there's still a lot to tune and control. *The default configuration is not suitable and optimal for large Ruby applications, and neither is there a one-size-fits-all set of tuned parameters that would suit every app.* However, hand-tuning the GC parameters is a slippery slope to navigate for most developers.

## We're fixing this

![tunemygc workflow diagram](https://raw.githubusercontent.com/bear-metal/tunemygc/master/assets/tunemygc-graphic2x-b3390590eadab5528577f4e0285330fd.png?token=AAABe8sM_ofiQkrCpNw7OYRbtHMLO9l5ks5UuQlYwA%3D%3D)

We also recently [blogged](http://bearmetal.eu/theden/2015-02-20-rails-garbage-collection-tuning-approaches) about how the product works.

## Benefits

* Faster boot times
* Less major GC cycles during requests
* Less worst case memory usage - it's bound by sensible upper limits and growth factors
* No need to keep up to date with the C Ruby GC as an evolving moving target
* [in progress] A repeatable process to infer an optimal GC config for that app's current state within the context of a longer development cycle.

## Benchmarks

We used [Discourse](http://www.discourse.org) as our primary test harness as it's representative of most Rails applications and has been instrumental in asserting RGenC developments on Rails as well.

[Discourse](http://www.discourse.org) throughput: [GC defaults](https://tunemygc.com/configs/c5214cfa00b3bf429badd2161c4b6a08) VS TuneMyGc [suggestions](https://tunemygc.com/configs/e129791f94159a8c75bef3a636c05798)

![tunemygc workflow diagram](https://raw.githubusercontent.com/bear-metal/tunemygc/master/assets/discourse_bench.png?token=AAABe8sM_ofiQkrCpNw7OYRbtHMLO9l5ks5UuQlYwA%3D%3D)

## Installing

#### OS X / Linux

Add to your Gemfile and run `bundle install`

``` sh
gem 'tunemygc'
```

This gem linterposes itself into the application and piggy backs off the new GC events in Ruby 2.x for introspection. Tuning recommendations are handled through a web service at `https://tunemygc.com`. You will need MRI Ruby `2.1`, or later. [Rails](http://www.rubyonrails.org) applications, background jobs, tests and any proprietary Ruby scripts and frameworks are supported.

## Getting started

There isn't much setup other than adding the gem to your Gemfile and running a single command from your application root to register your application with the `https://tunemygc.com` service:

``` sh
$ bundle exec tunemygc -r lourens@bearmetal.eu
Application registered. Use RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 in your environment.
```

We require a valid email address as a canonical reference for tuner tokens for your applications.

For the above command sequences, to sample your app or script for tuning, run (inject `RUBY_GC_TOKEN` and `RUBY_GC_TUNE` to your env):

``` sh
RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 RUBY_GC_TUNE=200 bundle exec rails s
```

And after some profiling requests, when the process terminates, you can visit the given report URL for a config recommendation and some further insights:

``` sh
[TuneMyGC, pid: 70160] Syncing 688 snapshots
[TuneMyGC, pid: 70160] ==== Recommended GC configs for ActionController
[TuneMyGC, pid: 70160] Please visit https://tunemygc.com/configs/d739119e4abc38d42e183d1361991818 to view your configuration and other Garbage Collector insights
```

The CLI interface supports retrieving configuration options for your application as well.

``` sh
$ bundle exec tunemygc
Usage: tunemygc [options]
    -r, --register EMAIL             Register this application with the https://tunemygc.com service
    -c, --config TOKEN               Fetch the last known config for a given application
    -h, --help                       How to use the TuneMyGC agent CLI
```

## Configuration options

We fully embrace and encourage [12 factor](http://12factor.net) conventions and as such configuration is limited to a few environment variables. No config files and YAML or initializer cruft.

#### Basic

* `RUBY_GC_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

This application specific token is required for GC instrumentation. You can generate one from the CLI interface by registering for the service with a valid email address:

``` sh
$ bundle exec tunemygc -r lourens@bearmetal.eu
Application registered. Use RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 in your environment.
```

* `RUBY_GC_TUNE=200`

Enables the interposer and controls it's lifetime for sampling processing. It takes a few lightweight snapshots and submits them to `tunemygc.com`. A value of `200` implies `200` units of work - Rails requests, tests, background jobs etc. Without this environment variable set, it won't interpose itself. A good minimum ballpark sample set would be 200.

For the above command sequences, to sample a Rails app for tuning, run:

``` sh
RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 RUBY_GC_TUNE=200 bundle exec rails s
```

And after some profiling requests, when the process terminates, you can visit the given report URL for a config recommendation and some further insights:

``` sh
[TuneMyGC, pid: 70160] Syncing 688 snapshots
[TuneMyGC, pid: 70160] ==== Recommended GC configs for ActionController
[TuneMyGC, pid: 70160] Please visit https://tunemygc.com/configs/d739119e4abc38d42e183d1361991818 to view your configuration and other Garbage Collector insights
```

#### Advanced

* `RUBY_GC_SPY=action_controller` (Spy on the GC for this type of processing. `action_controller`, `active_job`, `que_job`, `minitest` or `rspec` are supported)

Defines what type of processing you would like to sample for GC activity. An Action Controller spy is the default, but [ActiveJob](https://github.com/rails/rails/tree/master/activejob), [que](https://github.com/chanks/que), [minitest](https://github.com/seattlerb/minitest) and [rspec](http://rspec.info) are also supported as experimental features.

## How do I use this?

This gem is only a lightweight agent and designed to not get in your way. It samples your application during runtime, syncs data with our web service when it terminates and we provide a report URL where you can view a suggested GC configuration and additional tips and insights.

#### Interpreting results

An instrumented process dumps a report URL with a reccommended config to the Rails logger.

``` sh
[TuneMyGC, pid: 70160] Syncing 688 snapshots
[TuneMyGC, pid: 70160] ==== Recommended GC configs for ActionController
[TuneMyGC, pid: 70160] Please visit https://tunemygc.com/configs/d739119e4abc38d42e183d1361991818 to view your configuration and other Garbage Collector insights
```

We're still in the process of building tools and a launcher shim around this. You can also retrieve the last known configuration for you app via the CLI interface:

``` sh
$ bundle exec tunemygc -c 3b8796e5627f97ec760f000d55d9b3f5
=== Suggested GC configuration:

export RUBY_GC_HEAP_INIT_SLOTS=382429
export RUBY_GC_HEAP_FREE_SLOTS=603850
export RUBY_GC_HEAP_GROWTH_FACTOR=1.2
export RUBY_GC_HEAP_GROWTH_MAX_SLOTS=301925
export RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=2.0
export RUBY_GC_MALLOC_LIMIT=35818030
export RUBY_GC_MALLOC_LIMIT_MAX=42981636
export RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.32
export RUBY_GC_OLDMALLOC_LIMIT=32782669
export RUBY_GC_OLDMALLOC_LIMIT_MAX=49174003.5
export RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=1.2
```

We're busy working on adding tips on the report URLs for some common problem contexts.

#### Heroku and 12 factor

We have a [Heroku](http://www.heroku.com) addon in Alpha testing and the Ruby GC lends itself well to tuning through [12 factor](http://12factor.net) principles as it's designed around environment variables.

#### Custom hooks for add hoc scripts

Here's an example of instrumenting a custom worker script:

``` ruby
# inject the agent and force the manual spy
ENV['RUBY_GC_SPY'] ||= 'manual'
require 'tunemygc'

require 'timeout'
require 'queue_classic'

FailedQueue = QC::Queue.new("failed_jobs")

class MyWorker < QC::Worker
  def handle_failure(job, e)
    FailedQueue.enqueue(job[:method], *job[:args])
  end
end

worker = MyWorker.new

trap('INT') { exit }
trap('TERM') { worker.stop }

# Signal we're ready to start doing work
TuneMyGc.booted

loop do
  job = worker.lock_job
  Timeout::timeout(5) do
    # signal the start of a unit of work
    TuneMyGc.processing_started
    worker.process(job)
    # signal the end of a unit of work
    TuneMyGc.processing_ended
  end
end

# When the process exits, results are synced with the TuneMyGC service
```

## Security and privacy concerns

We don't track any data specific to your application other than a simple environment header which allows us to pick the best tuner for your setup:

* Ruby version eg. "2.2.0"
* Rails version eg. "4.1.8"
* Compile time GC options eg. "["USE_RGENGC", "RGENGC_ESTIMATE_OLDMALLOC", "GC_ENABLE_LAZY_SWEEP"]"
* Compile time GC constants eg. "{"RVALUE_SIZE"=>40, "HEAP_OBJ_LIMIT"=>408, "HEAP_BITMAP_SIZE"=>56, "HEAP_BITMAP_PLANES"=>3}"

Samples hitting our tuner endpoint doesn't include any proprietary details from your application either - just data points about GC activity.

We do however ask for a valid email address as a canonical reference for tuner tokens for your applications.

## Feedback and issues

When trouble strikes, please file an [issue](https://www.github.com/bear-metal/tunemygc/issues) or email the cubs directly <tunemygc@bearmetal.eu>

[Bear Metal](http://www.bearmetal.eu) is also available for consulting around general Rails performance, heap dump analysis (more tools coming soon) and custom Ruby extension development.

## License

(The MIT License)

Copyright (c) 2015:

* [Bear Metal](http://bearmetal.eu)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Credits

RSS measuring feature by David Robert Nadeau (http://NadeauSoftware.com/) under Creative Commons Attribution 3.0 Unported License (http://creativecommons.org/licenses/by/3.0/deed.en_US)