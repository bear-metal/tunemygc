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

We used [Discourse](http://www.discourse.org) as our primary test harness as it's representative of most Rails applications and has been instrumental in asserting RGenC developments on Rails.

## Installing

#### OS X / Linux
``` sh
gem install tunemygc
```

This gem linterposes itself into the Rails request / response lifecycles and piggy backs off the new GC events for introspection. Tuning recommendations are handled through a web service at `tunemygc.com`. You will need a `rails > 4.1`, installation and MRI Ruby `2.1`, or later.

#### Windows

Has not been tested at all.

## Configuration options

We fully embrace and encourage [12 factor](http://12factor.net) conventions and as such configuration is limited to a few environment variables. No config files and YAML or initializer cruft.

#### Basic

* `RUBY_GC_TUNE=1`

Enables the interposer for taking a few lightweight snapshots and submitting them to `tunemygc.com`. Without this environment variable set, it won't interpose itself.

#### Advanced

* `RUBY_GC_TUNE_REQUESTS=x`

Controls the interposer lifetime for sampling requests. It will enable itself, then remove request instrumentation after `x` requests.

* `RUBY_GC_TOKEN=x`

An identifier for your application. Reserved for future use.

* `RUBY_GC_TUNE_DEBUG=1`

As above, but dumps snapshots to Rails logger or STDOUT prior to submission. Mostly for developer use/support.

## How do I use this?

This gem is only a lightweight agent and designed to not get in your way. There's just not much workflow other than applying the suggested GC configuration to your application.

#### Interpreting configurations

An instrumented process dumps a reccommended config to the Rails logger.

``` sh
[TuneMyGC] == start speed config ==
[TuneMyGC] RUBY_GC_HEAP_INIT_SLOTS=552313
[TuneMyGC] RUBY_GC_HEAP_FREE_SLOTS=543666
[TuneMyGC] RUBY_GC_HEAP_GROWTH_FACTOR=1.2
[TuneMyGC] RUBY_GC_HEAP_GROWTH_MAX_SLOTS=271833
[TuneMyGC] RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=2.0
[TuneMyGC] RUBY_GC_MALLOC_LIMIT=64000000
[TuneMyGC] RUBY_GC_MALLOC_LIMIT_MAX=128000000
[TuneMyGC] RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.56
[TuneMyGC] RUBY_GC_OLDMALLOC_LIMIT=64000000
[TuneMyGC] RUBY_GC_OLDMALLOC_LIMIT_MAX=33554432
[TuneMyGC] RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=1.32
[TuneMyGC] == end speed config ==
```

We're still in the process of building tools and a launcher shim around this.

#### Heroku and 12 factor

We have a [Heroku](http://www.heroku.com) addon in Alpha testing and the Ruby GC lends itself to tuning through 12 factor principles as it's designed around environment variables.

## Security and privacy concerns

We don't track any data specific to your application other than a simple environment header which allows us to pick the best tuner for your setup:

* Ruby version eg. "2.2.0"
* Rails version eg. "4.1.8"
* Compile time GC options eg. "["USE_RGENGC", "RGENGC_ESTIMATE_OLDMALLOC", "GC_ENABLE_LAZY_SWEEP"]"
* Compile time GC constants eg. "{"RVALUE_SIZE"=>40, "HEAP_OBJ_LIMIT"=>408, "HEAP_BITMAP_SIZE"=>56, "HEAP_BITMAP_PLANES"=>3}"

Samples hitting our tuner endpoint doesn't include any proprietary details from your application either - just data points about GC activity.

## Feedback and issues

When trouble strikes, please file an [issue](https://www.github.com/bear-metal/tunemygc/issues)

[Bear Metal](http://www.bearmetal.eu) is also available for consulting around general Rails performance, heap dump analysis (more tools coming soon) and custom Ruby extension development.