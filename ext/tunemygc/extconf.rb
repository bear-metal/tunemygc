# encoding: utf-8

require 'mkmf'

dir_config('tunemygc')

# Only defined for Ruby 2.1.x and 2.2.x
gc_events = have_const('RUBY_INTERNAL_EVENT_GC_END_SWEEP')

if gc_events
  # From ko1/gc_tracer
  # Piggy backs off the new methods to retrieve GC stats and latest cycle info without doing
  # allocations - thus safe to call within a GC cycle and properly snapshot what we need without
  # the results being skewed by postponed jobs, which isn't deterministic.
  open("tunemygc_env.h", 'w'){|f|
    gc_stat = GC.stat
    gc_latest_info = GC.latest_gc_info
    f.puts '#include "ruby/ruby.h"'
    f.puts "static VALUE sym_gc_stat[#{gc_stat.keys.size}];"
    f.puts "static VALUE sym_latest_gc_info[#{gc_latest_info.keys.size}];"

    f.puts 'typedef struct {'
    f.puts '    double ts;'
    f.puts '    size_t peak_rss;'
    f.puts '    size_t current_rss;'
    f.puts '    VALUE stage;'
    gc_stat.keys.each do |key|
      f.puts "    size_t #{key};"
    end
    gc_latest_info.each do |key, val|
      f.puts "    VALUE #{key};"
    end
    f.puts '} tunemygc_stat_record;'

    f.puts "static void"
    f.puts "tunemygc_set_stat_record(tunemygc_stat_record *record)"
    f.puts "{"
      #
      gc_stat.keys.each.with_index{|k, i|
        f.puts "    record->#{k} = rb_gc_stat(sym_gc_stat[#{i}]);"
      }
      gc_latest_info.keys.each.with_index{|k, i|
        f.puts "    record->#{k} = rb_gc_latest_gc_info(sym_latest_gc_info[#{i}]);"
      }
      #
    f.puts "}"

    f.puts "static VALUE"
    f.puts "tunemygc_get_stat_record(tunemygc_stat_record *record)"
    f.puts "{"
      #
      f.puts  "    VALUE stat = rb_hash_new();"
      f.puts  "    VALUE latest_info = rb_hash_new();"
      f.puts  "    VALUE snapshot = rb_ary_new2(7);"
      gc_stat.keys.each.with_index{|k, i|
        f.puts "    rb_hash_aset(stat, sym_gc_stat[#{i}], SIZET2NUM(record->#{k}));"
      }
      gc_latest_info.keys.each.with_index{|k, i|
        f.puts "    rb_hash_aset(latest_info, sym_latest_gc_info[#{i}], record->#{k});"
      }
      f.puts "    rb_ary_store(snapshot, 0, DBL2NUM(record->ts));"
      f.puts "    rb_ary_store(snapshot, 1, SIZET2NUM(record->peak_rss));"
      f.puts "    rb_ary_store(snapshot, 2, SIZET2NUM(record->current_rss));"
      f.puts "    rb_ary_store(snapshot, 3, record->stage);"
      f.puts "    rb_ary_store(snapshot, 4, stat);"
      f.puts "    rb_ary_store(snapshot, 5, latest_info);"
      f.puts "    rb_ary_store(snapshot, 6, Qnil);"
      f.puts "    return snapshot;"
      #
    f.puts "}"

    f.puts "static void"
    f.puts "tunemygc_setup_trace_symbols(void)"
    f.puts "{"
      #
      gc_stat.keys.each.with_index{|k, i|
        f.puts "    sym_gc_stat[#{i}] = ID2SYM(rb_intern(\"#{k}\"));"
      }
      gc_latest_info.keys.each.with_index{|k, i|
        f.puts "    sym_latest_gc_info[#{i}] = ID2SYM(rb_intern(\"#{k}\"));"
      }
      #
    f.puts "}"
  }

  create_makefile('tunemygc/tunemygc_ext')
else
  # do nothing if we're not running within Ruby 2.1.x or 2.2.x
  File.open('Makefile', 'w') do |f|
    f.puts "install:\n\t\n"
  end
end
