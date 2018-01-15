use "time"

type _Runner is _RunSync

actor _RunSync
  let _ponybench: PonyBench
  embed _aggregator: _Aggregator
  let _name: String
  var _start_cpu_time: U64 = 0

  new create(ponybench: PonyBench, benchmark: MicroBenchmark) =>
    _ponybench = ponybench
    _aggregator = _Aggregator(_ponybench, this, benchmark.config())
    _name = benchmark.name()
    apply(consume benchmark)

  be apply(benchmark: MicroBenchmark) =>
    benchmark.before()
    _gc_next_behavior()
    _run_iteration(consume benchmark)

  be _run_iteration(benchmark: MicroBenchmark, n: U64 = 0) =>
    if n == _aggregator.iterations then
      let t' = Time.nanos()
      Time.perf_end()
      _complete(consume benchmark, t' - _start_cpu_time)
    else
      if n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        benchmark()?
        _run_iteration(consume benchmark, n + 1)
      else
        _fail()
      end
    end

  be _complete(benchmark: MicroBenchmark, t: U64) =>
    benchmark.after()
    _aggregator.complete(consume benchmark, t)

  be _fail() =>
    _ponybench._fail(_name)

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())
