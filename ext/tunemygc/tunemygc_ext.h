#ifndef TUNEMYGC_EXT_H
#define TUNEMYGC_EXT_H

#include "ruby/ruby.h"
#include "ruby/debug.h"

extern VALUE rb_mTunemygc;

#include <stddef.h>
/* for walltime */
#include <time.h>
#include <sys/time.h>

/* header we codegen'ed in extconf.rb from VM specific GC stats */
#include "tunemygc_env.h"

#endif
