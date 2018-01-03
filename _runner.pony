use "time"

actor _Runner
  let _ponybench: PonyBench

  // TODO document and make configurable per-benchmark
  let _iterations: U64 = 100_000
  let _warmup_iterations: U64 = 10

  var _warmup: Bool = true
  var _start_cpu_time: U64 = 0
  var _name: String = ""

  new create(ponybench: PonyBench) =>
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    _warmup = true
    _name = bench_data.benchmark.name()

    _run(consume bench_data)

  fun ref _run(bench_data: _BenchData) =>
    bench_data.results.clear()
    bench_data.benchmark.before()
    _gc_next_behavior()
    _run_iteration(consume bench_data,
      if _warmup then _warmup_iterations else _iterations end)

  be _run_iteration(bench_data: _BenchData, n: U64) =>
    if n == 0 then
      _complete(consume bench_data)
    else
      try \likely\
        Time.perf_begin()
        let t = Time.nanos()
        bench_data.benchmark()?
        let t' = Time.nanos()
        Time.perf_end()
        bench_data.results.push(t' - t)
      else
        _fail()
        return
      end
      _gc_next_behavior()
      _run_iteration(consume bench_data, n - 1)
    end

  fun ref _complete(bench_data: _BenchData) =>
    bench_data.benchmark.after()
    if _warmup then
      _warmup = false
      _run(consume bench_data)
    else
      bench_data.iterations = _iterations
      _ponybench._complete(consume bench_data)
    end

  fun ref _fail() =>
    _ponybench._fail(_name)

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())
