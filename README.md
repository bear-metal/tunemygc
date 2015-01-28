## [TuneMyGC](https://www.tunemygc.com) - optimal MRI Ruby 2.1+ Garbage Collection

[![Build Status](https://travis-ci.org/bear-metal/tunemygc.svg)](https://travis-ci.org/bear-metal/tunemygc)

The Ruby garbage collector has been flagged as the crux of Ruby performance and memory use for a long time. It has improved a lot over the last years, but there's still a lot to tune and control. *The default configuration is not suitable and optimal for Rails applications, and neither is there a one-size-fits-all set of tuned parameters that would suit every app.* However, hand-tuning the GC parameters is a slippery slope to navigate for most developers.

## We're fixing this

![tunemygc workflow diagram](https://raw.githubusercontent.com/bear-metal/tunemygc/master/assets/tunemygc-graphic2x-80dac1571cacc70d9b272bb62ae9f6df.png?token=AAABe8sM_ofiQkrCpNw7OYRbtHMLO9l5ks5UuQlYwA%3D%3D)

## Benefits

* Faster boot times
* Less major GC cycles during requests
* Less worst case memory usage - it's bound by sensible upper limits and growth factors
* No need to keep up to date with the C Ruby GC as an evolving moving target
* [in progress] A repeatable process to infer an optimal GC config for that app's current state within the context of a longer development cycle.

## Benchmarks

We used [Discourse](http://www.discourse.org) as our primary test harness as it's representative of most Rails applications and has been instrumental in asserting RGenC developments on Rails as well.

![tunemygc workflow diagram](https://raw.githubusercontent.com/bear-metal/tunemygc/master/assets/discourse_bench.png?token=AAABe8sM_ofiQkrCpNw7OYRbtHMLO9l5ks5UuQlYwA%3D%3D)

## Installing

#### OS X / Linux

Add to your Gemfile and run `bundle install`

``` sh
gem 'tunemygc'
```
This gem linterposes itself into the Rails request/response lifecycles and piggy backs off the new GC events in Ruby 2.x for introspection. Tuning recommendations are handled through a web service at `https://tunemygc.com`. You will need a `rails > 4.1`, installation and MRI Ruby `2.1`, or later.

#### Windows

Has not been tested at all.

## Getting started

There isn't much setup other than adding the gem to your Gemfile and running a single command from your application root to register your application with the `https://tunemygc.com` service:

``` sh
Lourenss-MacBook-Air-2:discourse lourens$ bundle exec tunemygc -r lourens@bearmetal.eu
Application registered. Use RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 in your environment.
```

We require a valid email address as a canonical reference for tuner tokens for your applications.

For the above command sequences, to sample your Rails app for tuning, run:

``` sh
RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 RUBY_GC_TUNE=1 bundle exec rails s
```

The CLI interface supports retrieving configuration options for your application as well.

``` sh
Lourenss-MacBook-Air-2:discourse lourens$ bundle exec tunemygc
Usage: tunemygc [options]
    -r, --register EMAIL             Register this Rails app with the https://tunemygc.com service
    -c, --config TOKEN               Fetch the last known config for a given Rails app
    -h, --help                       How to use the TuneMyGC agent CLI
```

## Configuration options

We fully embrace and encourage [12 factor](http://12factor.net) conventions and as such configuration is limited to a few environment variables. No config files and YAML or initializer cruft.

#### Basic

* `RUBY_GC_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

This application specific token is required for GC instrumentation. You can generate one from the CLI interface by registering for the service with a valid email address:

``` sh
Lourenss-MacBook-Air-2:discourse lourens$ bundle exec tunemygc -r lourens@bearmetal.eu
Application registered. Use RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 in your environment.
```

* `RUBY_GC_TUNE=1`

Enables the interposer for taking a few lightweight snapshots and submitting them to `tunemygc.com`. Without this environment variable set, it won't interpose itself.

For the above command sequences, to sample my Rails app for tuning, I'd run:

``` sh
RUBY_GC_TOKEN=08de9e8822c847244b31290cedfc1d51 RUBY_GC_TUNE=1 bundle exec rails s
```

#### Advanced

* `RUBY_GC_TUNE_REQUESTS=x`

Controls the interposer lifetime for sampling requests. It will enable itself, then remove request instrumentation after `x` requests. A good minimum ballpark sample set would be 200

* `RUBY_GC_TUNE_DEBUG=1`

As above, but dumps snapshots to Rails logger or STDOUT prior to submission. Mostly for developer use/support.

## How do I use this?

This gem is only a lightweight agent and designed to not get in your way. There's not much workflow at the moment other than applying the suggested GC configuration to your application's environment.

#### Interpreting configurations

An instrumented process dumps a reccommended config to the Rails logger.

``` sh
[TuneMyGC] Syncing 688 snapshots
[TuneMyGC] ==== Recommended GC configs from https://tunemygc.com/configs/d739119e4abc38d42e183d1361991818.json
[TuneMyGC] export RUBY_GC_HEAP_INIT_SLOTS=382429
[TuneMyGC] export RUBY_GC_HEAP_FREE_SLOTS=603850
[TuneMyGC] export RUBY_GC_HEAP_GROWTH_FACTOR=1.2
[TuneMyGC] export RUBY_GC_HEAP_GROWTH_MAX_SLOTS=301925
[TuneMyGC] export RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=2.0
[TuneMyGC] export RUBY_GC_MALLOC_LIMIT=35818030
[TuneMyGC] export RUBY_GC_MALLOC_LIMIT_MAX=42981636
[TuneMyGC] export RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.32
[TuneMyGC] export RUBY_GC_OLDMALLOC_LIMIT=32782669
[TuneMyGC] export RUBY_GC_OLDMALLOC_LIMIT_MAX=49174003.5
[TuneMyGC] export RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=1.2
```

We're still in the process of building tools and a launcher shim around this. You can also retrieve the last known configuration for you app via the CLI interface:

``` sh
Lourenss-MacBook-Air-2:discourse lourens$ bundle exec tunemygc -c 3b8796e5627f97ec760f000d55d9b3f5
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

#### Heroku and 12 factor

We have a [Heroku](http://www.heroku.com) addon in Alpha testing and the Ruby GC lends itself well to tuning through 12 factor principles as it's designed around environment variables.

## Security and privacy concerns

We don't track any data specific to your application other than a simple environment header which allows us to pick the best tuner for your setup:

* Ruby version eg. "2.2.0"
* Rails version eg. "4.1.8"
* Compile time GC options eg. "["USE_RGENGC", "RGENGC_ESTIMATE_OLDMALLOC", "GC_ENABLE_LAZY_SWEEP"]"
* Compile time GC constants eg. "{"RVALUE_SIZE"=>40, "HEAP_OBJ_LIMIT"=>408, "HEAP_BITMAP_SIZE"=>56, "HEAP_BITMAP_PLANES"=>3}"

Samples hitting our tuner endpoint doesn't include any proprietary details from your application either - just data points about GC activity.

We do however ask for a valid email address as a canonical reference for tuner tokens for your applications.

## Feedback and issues

When trouble strikes, please file an [issue](https://www.github.com/bear-metal/tunemygc/issues)

[Bear Metal OÜ](http://www.bearmetal.eu) is also available for consulting around general Rails performance, heap dump analysis (more tools coming soon) and custom Ruby extension development.

## License

(The MIT License)

Copyright (c) 2015:

* [Bear Metal OÜ](http://bearmetal.eu)

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