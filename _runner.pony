use "time"

trait tag _Runner
  be apply()

actor _RunSync is _Runner
  let _ponybench: PonyBench
  embed _aggregator: _Aggregator
  let _name: String
  let _bench: MicroBenchmark
  var _start_cpu_time: U64 = 0

  new create(ponybench: PonyBench, benchmark: MicroBenchmark) =>
    _ponybench = ponybench
    _aggregator = _Aggregator(_ponybench, this, benchmark.config())
    _name = benchmark.name()
    _bench = consume benchmark
    apply()

  be apply() =>
    _bench.before()
    _gc_next_behavior()
    _run_iteration()

  be _run_iteration(n: U64 = 0) =>
    if n == _aggregator.iterations then
      let t' = Time.nanos()
      Time.perf_end()
      _complete(t' - _start_cpu_time)
    else
      if n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        _bench()?
        _run_iteration(n + 1)
      else
        _fail()
      end
    end

  be _complete(t: U64) =>
    _bench.after()
    _aggregator.complete(_name, t)

  be _fail() =>
    _ponybench._fail(_name)

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())

actor _RunAsync is _Runner
  let _ponybench: PonyBench
  embed _aggregator: _Aggregator
  let _name: String
  let _bench: AsyncMicroBenchmark ref
  var _start_cpu_time: U64 = 0
  var _end_cpu_time: U64 = 0
  var _n: U64 = 0

  embed _before_cont: AsyncBenchContinue =
    AsyncBenchContinue._create(this, recover this~_apply_cont() end)
  embed _bench_cont: AsyncBenchContinue =
    AsyncBenchContinue._create(this, recover this~_run_iteration() end)
  embed _after_cont: AsyncBenchContinue =
    AsyncBenchContinue._create(this, recover this~_complete_cont() end)

  new create(ponybench: PonyBench, benchmark: AsyncMicroBenchmark) =>
    _ponybench = ponybench
    _aggregator = _Aggregator(_ponybench, this, benchmark.config())
    _name = benchmark.name()
    _bench = consume benchmark
    apply()

  be apply() =>
    _bench.before(_before_cont)

  be _apply_cont() =>
    _n = 0
    _gc_next_behavior()
    _run_iteration()

  be _run_iteration() =>
    if _n == _aggregator.iterations then
      _end_cpu_time = Time.nanos()
      Time.perf_end()
      _complete()
    else
      if _n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        _n = _n + 1
        _bench(_bench_cont)?
        // _run_iteration(n + 1)
      else
        _fail()
      end
    end

  be _complete() =>
    _bench.after(_after_cont)

  be _complete_cont() =>
    let t = _end_cpu_time - _start_cpu_time
    _aggregator.complete(_name, t)

  be _fail() =>
    _ponybench._fail(_name)

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())

class val AsyncBenchContinue
  let _run_async: _RunAsync
  let _f: {()} val

  new val _create(run_async: _RunAsync, f: {()} val) =>
    _run_async = run_async
    _f = f

  fun complete() =>
    _f()

  fun fail() =>
    _run_async._fail()
