# TuneMyGC Protocol

The tuning service depends on a simple JSON over HTTP protocol. A set of samples are collected during the lifetime of a process and synced with the service when the process terminates. This document serves as an initial specification for third party agents and other infrastructure to integrate with TuneMyGC.

## Application lifecycle events

A few events are important during the lifetime of a process for the tuner to gain valuable insights into how well the Garbage Collector is working and how to further optimise it.

### BOOTED

Triggered when the application is ready to start doing work. For Rails application, this is typically when the app has been fully loaded in Production, ready to serve requests, to accept background work etc. All source files have been loaded and most resources acquired.

### PROCESSING_STARTED

Emitted at the start of a unit of work. Typically the start of a HTTP request, when a background job has been popped off a queue, the start of a test case or any other type of processing that is the primary purpose of running the process.

### PROCESSING_ENDED

Emitted at the end of a unit of work. Typically the end of a HTTP request, when a background job has been popped off a queue, the end of a test case or any other type of processing that is the primary purpose of running the process.

### GC_CYCLE_STARTED

Emitted when a Garbage Collection cycle starts. Can be interleaved with PROCESSING specific events due to lazy sweeping features of the Garbage Collector, which interleaves normal VM operations with a Garbage Collection cycle.

### GC_CYCLE_ENDED

Emitted when a Garbage Collection cycle ended.

### TERMINATED

Triggered when the application terminates, just before syncing samples with the TuneMyGC service.

## Connection information

The service listens on <code>https://tunemygc.com/ruby</code> and responds to <code>POST</code> requests. SSL transport is required. We opted for embedding metadata such as application identifiers, Ruby plaform info etc. as a header element in the sample set in order to simplify integration with most HTTP clients.

## The payload

The payload is a JSON encoded Array of samples, with the first element being a special header that describes the environment (Rails version, Ruby version etc.) where the samples originated from. There's no limit imposed on the amount of samples, other than a 50MB raw upload limit which our HTTP frontend would reject on violation.

### Sample set example

Here's an example for a very short application lifecycle: a few GC cycles after booting the app, processing a single request and then terminating.

```json
[["09dddb3e2e9d5d16ec093cd313f4ff80","2.2.0","4.1.8",{"RUBY_GC_TUNE_HOST":"localhost:5000","RUBY_GC_TUNE":"1"},"1.0.15",["USE_RGENGC","RGENGC_ESTIMATE_OLDMALLOC","GC_ENABLE_LAZY_SWEEP"],{"RVALUE_SIZE":40,"HEAP_OBJ_LIMIT":408,"HEAP_BITMAP_SIZE":56,"HEAP_BITMAP_PLANES":3},["count","heap_allocated_pages","heap_sorted_length","heap_allocatable_pages","heap_available_slots","heap_live_slots","heap_free_slots","heap_final_slots","heap_marked_slots","heap_swept_slots","heap_eden_pages","heap_tomb_pages","total_allocated_pages","total_freed_pages","total_allocated_objects","total_freed_objects","malloc_increase_bytes","malloc_increase_bytes_limit","minor_gc_count","major_gc_count","remembered_wb_unprotected_objects","remembered_wb_unprotected_objects_limit","old_objects","old_objects_limit","oldmalloc_increase_bytes","oldmalloc_increase_bytes_limit"],"localhost",1,153],[1422023921.481364,132255744,132255744,"BOOTED",[45,1354,1368,0,551887,319759,232128,0,319748,232138,1354,0,1354,0,3191859,2872100,1280,22439940,36,9,10683,21366,291638,583276,1664,23221058],{"major_by":"force","gc_by":"method","have_finalizer":false,"immediate_sweep":true,"state":"none"},null],[1422023921.776498,133820416,133820416,"GC_CYCLE_STARTED",[46,1354,1368,0,551887,550614,1273,0,319748,232138,1354,0,1354,0,3423988,2873374,0,21991141,36,9,10683,21366,291637,583276,0,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"none"},null],[1422023922.952984,135487488,135487488,"PROCESSING_STARTED",[46,1354,1368,0,551887,550292,1595,0,353935,82038,1354,0,1354,0,3505836,2955544,885712,21991141,37,9,10983,21366,318878,583276,886096,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null],[1422023923.144252,138760192,138760192,"GC_CYCLE_ENDED",[46,1354,1368,0,551887,551576,311,0,353935,197952,1354,0,1354,0,3621836,3070260,2910064,21991141,37,9,10983,21366,318878,583276,2910064,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null],[1422023923.14436,138768384,138768384,"GC_CYCLE_STARTED",[47,1354,1368,0,551887,551665,222,0,353935,197952,1354,0,1354,0,3621925,3070260,0,21551318,37,9,10983,21366,318878,583276,2914224,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"none"},null],[1422023923.395543,142356480,142356480,"GC_CYCLE_ENDED",[47,1354,1368,0,551887,551805,82,0,382464,169422,1354,0,1354,0,3791265,3239460,1428176,21551318,38,9,11156,21366,339590,583276,4223920,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null],[1422023923.395638,142360576,142360576,"GC_CYCLE_STARTED",[48,1354,1368,0,551887,551873,14,0,382464,169422,1354,0,1354,0,3791333,3239460,0,21120291,38,9,11156,21366,339590,583276,4228048,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"none"},null],[1422023924.422288,189997056,189997056,"GC_CYCLE_ENDED",[48,2357,2437,79,960702,953883,6819,0,393242,600508,2357,0,2357,0,4352680,3398797,20876224,21120291,39,9,11159,21366,361238,583276,25098416,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null],[1422023924.459472,190222336,190222336,"GC_CYCLE_STARTED",[49,2357,2437,79,960702,958426,2276,0,393242,600508,2357,0,2357,0,4357318,3398892,0,29568470,39,9,11159,21366,361238,583276,25342528,27318891],{"major_by":null,"gc_by":"malloc","have_finalizer":false,"immediate_sweep":false,"state":"none"},null],[1422023924.8609,191332352,191332352,"PROCESSING_ENDED",[49,2357,2437,79,960702,802035,158667,0,441562,278483,2195,162,2357,0,4447499,3645464,156448,29568470,40,9,11445,21366,416188,583276,19693888,27318891],{"major_by":null,"gc_by":"malloc","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null]]
```

### Sample set header

The header is a simple tuple structure with 11 elements.

Example:

```json
["09dddb3e2e9d5d16ec093cd313f4ff80","2.2.0","4.1.8",{"RUBY_GC_TUNE":"1"},"1.0.15",["USE_RGENGC","RGENGC_ESTIMATE_OLDMALLOC","GC_ENABLE_LAZY_SWEEP"],{"RVALUE_SIZE":40,"HEAP_OBJ_LIMIT":408,"HEAP_BITMAP_SIZE":56,"HEAP_BITMAP_PLANES":3},["count","heap_allocated_pages","heap_sorted_length","heap_allocatable_pages","heap_available_slots","heap_live_slots","heap_free_slots","heap_final_slots","heap_marked_slots","heap_swept_slots","heap_eden_pages","heap_tomb_pages","total_allocated_pages","total_freed_pages","total_allocated_objects","total_freed_objects","malloc_increase_bytes","malloc_increase_bytes_limit","minor_gc_count","major_gc_count","remembered_wb_unprotected_objects","remembered_wb_unprotected_objects_limit","old_objects","old_objects_limit","oldmalloc_increase_bytes","oldmalloc_increase_bytes_limit"],"localhost",1,153]
```

The respective tuple elements are:

* A unique and valid application identifier. Position 0, a String value such as <code>09dddb3e2e9d5d16ec093cd313f4ff80</code>
* The Ruby version. Position 1, a String value such as <code>2.2.0</code>
* Rails framework version. Position 2, a String value such as <code>4.1.8</code>
* Any existing RUBY_GC_* environment variables in the application environment. Position 3, a Hash value such as <code>{"RUBY_GC_TUNE"=>"1"}</code>
* TuneMyGC agent version. Position 4, a String value such as <code>1.0.15</code>
* Compile time GC constants. Position 5, an Array value such as <code>["USE_RGENGC", "RGENGC_ESTIMATE_OLDMALLOC", "GC_ENABLE_LAZY_SWEEP"]</code>
* Compile time GC options. Position 6, a Hash value such as <code>{"RVALUE_SIZE"=>40, "HEAP_OBJ_LIMIT"=>408, "HEAP_BITMAP_SIZE"=>56, "HEAP_BITMAP_PLANES"=>3}</code>
* Keys from <code>GC.stat</code> output - it allows individual samples to be more compact and only contain values mapping to these keys. Position 7, an Array value such as <code>["count", "heap_allocated_pages", "heap_sorted_length", "heap_allocatable_pages", "heap_available_slots", "heap_live_slots", "heap_free_slots", "heap_final_slots", "heap_marked_slots", "heap_swept_slots", "heap_eden_pages", "heap_tomb_pages", "total_allocated_pages", "total_freed_pages", "total_allocated_objects", "total_freed_objects", "malloc_increase_bytes", "malloc_increase_bytes_limit", "minor_gc_count", "major_gc_count", "remembered_wb_unprotected_objects", "remembered_wb_unprotected_objects_limit", "old_objects", "old_objects_limit", "oldmalloc_increase_bytes", "oldmalloc_increase_bytes_limit"]</code>
* Hostname. Position 8, a String value such as <code>localhost</code>
* Parent process identifier (ppid). Position 9, an Integer value such as <code>1</code>
* Process identifier (pid). Position 10, an Integer value such as <code>153</code>

### Sample set samples

Samples are simple tuple structures with 11 elements.

Example:

```json
[70201748333020,1422023921.481364,132255744,132255744,"BOOTED",[45,1354,1368,0,551887,319759,232128,0,319748,232138,1354,0,1354,0,3191859,2872100,1280,22439940,36,9,10683,21366,291638,583276,1664,23221058],{"major_by":"force","gc_by":"method","have_finalizer":false,"immediate_sweep":true,"state":"none"},null]
```

* Current thread identifier. Position 0, a Numerict value such as <code>70201748333020</code>
* Timestamp. Position 1, a Float value such as <code>1422023921.481364</code>
* Peak process RSS memory usage. Position 2, an Integer value such as <code>132255744</code>
* Current process RSS memory usage. Position 3, an Integer value such as <code>132255744</code>
* Event / sample type. Position 4, a String value such as <code>BOOTED</code>. Valid events: <code>BOOTED</code>, <code>GC_CYCLE_STARTED</code>, <code>GC_CYCLE_ENDED</code>, <code>PROCESSING_STARTED</code>, <code>PROCESSING_ENDED</code> and <code>TERMINATED</code>
* Garbage Collection metrics - values of <code>GC.stat</code> output. Position 5, an Array value such as <code>[45,1354,1368,0,551887,319759,232128,0,319748,232138,1354,0,1354,0,3191859,2872100,1280,22439940,36,9,10683,21366,291638,583276,1664,23221058]</code>
* Information from the latest GC cycle - output of <code>GC.latest_gc_info</code> Position 6, a Hash value such as <code>{"major_by"=>"force", "gc_by"=>"method", "have_finalizer"=>false, "immediate_sweep"=>true, "state"=>"none"}</code>
* Reserved for future use - metadata. <code>GC.latest_gc_info</code> Position 7, a Hash or nil value such as <code>{"path"=>"stats"}</code>

#### BOOTED

Triggered when the application is ready to start doing work. Also includes additional metadata about object type distribution in the Ruby heap.

Example:

```json
[70201748333020,1422023921.481364,132255744,132255744,"BOOTED",[45,1354,1368,0,551887,319759,232128,0,319748,232138,1354,0,1354,0,3191859,2872100,1280,22439940,36,9,10683,21366,291638,583276,1664,23221058],{"major_by":"force","gc_by":"method","have_finalizer":false,"immediate_sweep":true,"state":"none"},{"TOTAL":33016,"FREE":260,"T_OBJECT":963,"T_CLASS":911,"T_MODULE":45,"T_FLOAT":7,"T_STRING":18985,"T_REGEXP":387,"T_ARRAY":2803,"T_HASH":191,"T_STRUCT":222,"T_BIGNUM":2,"T_FILE":233,"T_DATA":1391,"T_MATCH":519,"T_COMPLEX":1,"T_NODE":6045,"T_ICLASS":48,"T_ZOMBIE":3}]
```

#### GC_CYCLE_STARTED

Emitted when a Garbage Collection cycle starts.

Example:

```json
[70201748333020,1422023921.776498,133820416,133820416,"GC_CYCLE_STARTED",[46,1354,1368,0,551887,550614,1273,0,319748,232138,1354,0,1354,0,3423988,2873374,0,21991141,36,9,10683,21366,291637,583276,0,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"none"},null]
```

#### GC_CYCLE_ENDED

Emitted when a Garbage Collection cycle ends.

Example:

```json
[70201748333020,1422023923.144252,138760192,138760192,"GC_CYCLE_ENDED",[46,1354,1368,0,551887,551576,311,0,353935,197952,1354,0,1354,0,3621836,3070260,2910064,21991141,37,9,10983,21366,318878,583276,2910064,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null]
```

#### PROCESSING_STARTED

Emitted at the start of a unit of work.

Example:

```json
[70201748333020,1422023922.952984,135487488,135487488,"PROCESSING_STARTED",[46,1354,1368,0,551887,550292,1595,0,353935,82038,1354,0,1354,0,3505836,2955544,885712,21991141,37,9,10983,21366,318878,583276,886096,22765743],{"major_by":null,"gc_by":"newobj","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null]
```

#### PROCESSING_ENDED:

Emitted at the end of a unit of work.

Example:

```json
[70201748333020,1422023924.8609,191332352,191332352,"PROCESSING_ENDED",[49,2357,2437,79,960702,802035,158667,0,441562,278483,2195,162,2357,0,4447499,3645464,156448,29568470,40,9,11445,21366,416188,583276,19693888,27318891],{"major_by":null,"gc_by":"malloc","have_finalizer":false,"immediate_sweep":false,"state":"sweeping"},null]
```

#### TERMINATED

Triggered when the application terminates. Also includes additional metadata about object type distribution in the Ruby heap.

Example:

```json
[70201748333020,1422023962.011763,204525568,195096576,"TERMINATED",[76,2357,2437,174,960702,466696,494006,0,465869,494832,2183,174,2357,0,14999220,14532524,37216,17136915,64,12,11707,23412,434060,868122,37600,26258064],{"major_by":"force","gc_by":"method","have_finalizer":false,"immediate_sweep":true,"state":"none"},{"TOTAL":33016,"FREE":260,"T_OBJECT":963,"T_CLASS":911,"T_MODULE":45,"T_FLOAT":7,"T_STRING":18985,"T_REGEXP":387,"T_ARRAY":2803,"T_HASH":191,"T_STRUCT":222,"T_BIGNUM":2,"T_FILE":233,"T_DATA":1391,"T_MATCH":519,"T_COMPLEX":1,"T_NODE":6045,"T_ICLASS":48,"T_ZOMBIE":3}]
```

## HTTP Response codes

### 200 Success

We were able to successfully tune your Rails application. Response body contains a callback URL that returns the configuration via HTTP GET.

Example response body:

```json
https://tunemygc.com/configs/e129791f94159a8c75bef3a636c05798
```

### 404 Not Found 

Invalid application token. Contact us at tunemygc@bearmetal.eu to resolve

### 501 Not Implemented

Either the Ruby or Rails versions are not supported.

### 426 Upgrade Required

The agent (protocol) version requires an upgrade. Response body defines the minimum supported version.

### 412 Precondition Failed

The GC is already tuned by environment variables, We respect that for most cases, but won't do a reccommendation when the tuner detects that we might clobber the existing config by too much. Response body is a JSON encoded Hash of existing RUBY_GC_* environment variables.

### 400 Bad Request

Invalid or corrupted payload. The response body defines what violated the protocol.

### 500 Internal Server Error

An unknown error occurred.

## Integrations and Support

This is an initial draft specification to explore the viability of third party integrations. Please reach out via email to tunemygc@bearmetal.eu if any additional information or support is desired.