#include "tunemygc_ext.h"

VALUE rb_mTunemygc;
static ID id_tunemygc_tracepoint;
static ID id_tunemygc_raw_snapshot;

static VALUE sym_gc_cycle_start;
static VALUE sym_gc_cycle_end;

/* For 2.2.x incremental GC */
#ifdef RUBY_INTERNAL_EVENT_GC_ENTER
static VALUE sym_gc_cycle_enter;
static VALUE sym_gc_cycle_exit;
#endif

/* From @tmm1/gctools */
static double _tunemygc_walltime()
{
  struct timespec ts;
#ifdef HAVE_CLOCK_GETTIME
  if (clock_gettime(CLOCK_REALTIME, &ts) == -1) {
    rb_sys_fail("clock_gettime");
  }
#else
  {
    struct timeval tv;
    if (gettimeofday(&tv, 0) < 0) {
      rb_sys_fail("gettimeofday");
    }
    ts.tv_sec = tv.tv_sec;
    ts.tv_nsec = tv.tv_usec * 1000;
  }
#endif
  return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static VALUE tunemygc_walltime(VALUE mod)
{
    return DBL2NUM(_tunemygc_walltime());
}

/* Postponed job callback that fires when the VM is in a consistent state again (sometime
 * after the GC cycle, notably RUBY_INTERNAL_EVENT_GC_END_SWEEP)
 */
static void tunemygc_invoke_gc_snapshot(void *data)
{
    tunemygc_stat_record *stat = (tunemygc_stat_record *)data;
    VALUE snapshot = tunemygc_get_stat_record(stat);
    rb_funcall(rb_mTunemygc, id_tunemygc_raw_snapshot, 1, snapshot);
    free(stat);
	}

/* GC tracepoint hook. Snapshots GC state using new low level helpers which are safe
 * to call from within tracepoint handlers as they don't allocate and change the heap state
 */
static void tunemygc_gc_hook_i(VALUE tpval, void *data)
{
    rb_trace_arg_t *tparg = rb_tracearg_from_tracepoint(tpval);
    rb_event_flag_t flag = rb_tracearg_event_flag(tparg);
    tunemygc_stat_record *stat = ((tunemygc_stat_record*)malloc(sizeof(tunemygc_stat_record)));
    stat->ts = _tunemygc_walltime();
    switch (flag) {
        case RUBY_INTERNAL_EVENT_GC_START:
            stat->stage = sym_gc_cycle_start;
            break;
        case RUBY_INTERNAL_EVENT_GC_END_SWEEP:
            stat->stage = sym_gc_cycle_end;
            break;
#ifdef RUBY_INTERNAL_EVENT_GC_ENTER
        case RUBY_INTERNAL_EVENT_GC_ENTER:
            stat->stage = sym_gc_cycle_enter;
            break;
        case RUBY_INTERNAL_EVENT_GC_EXIT:
            stat->stage = sym_gc_cycle_exit;
            break;
#endif
    }

    tunemygc_set_stat_record(stat);
    rb_postponed_job_register(0, tunemygc_invoke_gc_snapshot, (void *)stat);
}

/* Installs the GC tracepoint and declare interest only in start of the cycle and end of sweep
 * events
 */
static VALUE tunemygc_install_gc_tracepoint(VALUE mod)
{
    rb_event_flag_t events;
    VALUE tunemygc_tracepoint = rb_ivar_get(rb_mTunemygc, id_tunemygc_tracepoint);
    if (!NIL_P(tunemygc_tracepoint)) {
        rb_tracepoint_disable(tunemygc_tracepoint);
        rb_ivar_set(rb_mTunemygc, id_tunemygc_tracepoint, Qnil);
    }
    /* For 2.2.x incremental GC */
#ifdef RUBY_INTERNAL_EVENT_GC_ENTER
    events = RUBY_INTERNAL_EVENT_GC_START | RUBY_INTERNAL_EVENT_GC_END_SWEEP | RUBY_INTERNAL_EVENT_GC_ENTER | RUBY_INTERNAL_EVENT_GC_EXIT;
#else
    events = RUBY_INTERNAL_EVENT_GC_START | RUBY_INTERNAL_EVENT_GC_END_SWEEP;
#endif
    tunemygc_tracepoint = rb_tracepoint_new(0, events, tunemygc_gc_hook_i, (void *)0);
    if (NIL_P(tunemygc_tracepoint)) rb_warn("Could not install GC tracepoint!");
    rb_tracepoint_enable(tunemygc_tracepoint);
    rb_ivar_set(rb_mTunemygc, id_tunemygc_tracepoint, tunemygc_tracepoint);
    return Qnil;
}

/* Removes a previously enabled GC tracepoint */
static VALUE tunemygc_uninstall_gc_tracepoint(VALUE mod)
{
    VALUE tunemygc_tracepoint = rb_ivar_get(rb_mTunemygc, id_tunemygc_tracepoint);
    if (!NIL_P(tunemygc_tracepoint)) {
        rb_tracepoint_disable(tunemygc_tracepoint);
        rb_ivar_set(rb_mTunemygc, id_tunemygc_tracepoint, Qnil);
    }
    return Qnil;
}

void Init_tunemygc_ext()
{
    /* Warm up the symbol table */
    id_tunemygc_tracepoint = rb_intern("__tunemygc_tracepoint");
    id_tunemygc_raw_snapshot = rb_intern("raw_snapshot");
    rb_funcall(rb_mGC, rb_intern("stat"), 0);
    rb_funcall(rb_mGC, rb_intern("latest_gc_info"), 0);

    /* Symbol warmup */
    sym_gc_cycle_start = ID2SYM(rb_intern("GC_CYCLE_START"));
    sym_gc_cycle_end = ID2SYM(rb_intern("GC_CYCLE_END"));

    /* For 2.2.x incremental GC */
#ifdef RUBY_INTERNAL_EVENT_GC_ENTER
    sym_gc_cycle_enter = ID2SYM(rb_intern("GC_CYCLE_ENTER"));
    sym_gc_cycle_exit = ID2SYM(rb_intern("GC_CYCLE_EXIT"));
#endif

    tunemygc_setup_trace_symbols();

    rb_mTunemygc = rb_define_module("TuneMyGc");
    rb_ivar_set(rb_mTunemygc, id_tunemygc_tracepoint, Qnil);

    rb_define_module_function(rb_mTunemygc, "install_gc_tracepoint", tunemygc_install_gc_tracepoint, 0);
    rb_define_module_function(rb_mTunemygc, "uninstall_gc_tracepoint", tunemygc_uninstall_gc_tracepoint, 0);

    rb_define_module_function(rb_mTunemygc, "walltime", tunemygc_walltime, 0);
}
