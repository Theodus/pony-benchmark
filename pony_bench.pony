use "collections" // TODO remove

actor PonyBench
  let _env: Env
  embed _bench_q: Array[MicroBenchmark] = Array[MicroBenchmark]
  let _runner: _Runner = _Runner(this)
  var _running: Bool = false
  var _overhead: U64 = 0

  new create(env: Env, list: BenchmarkList) =>
    _env = env
    _overhead_benchmark()
    list.benchmarks(this)

  be apply(bench: MicroBenchmark) =>
    _bench_q.push(consume bench)
    // if not _running then
    //   // Kick off the first benchmark
    //   _running = true
    //   _next_benchmark(_BenchData.null())
    // end

  fun ref _overhead_benchmark() =>
    _running = true
    _runner(_BenchData.overhead())

  fun ref _next_benchmark(bench_data: _BenchData) =>
    if _bench_q.size() > 0 then
      try
        bench_data.reset(_bench_q.shift()?)
        _runner(consume bench_data)
      end
    else
      _running = false
    end

  be _complete(bench_data: _BenchData) =>
    if bench_data.benchmark.name() == "overhead" then
      _overhead = bench_data.mean()
      _env.out.print("overhead: " + _overhead.string() + "\n")
    else
      let total_runtime = bench_data.sum()
      let iters = bench_data.iterations
      _env.out.print(bench_data.benchmark.name() + ":")
      _env.out.print("iterations: " + iters.string())
      _env.out.print("total runtime: " + total_runtime.string() + " ns")
      let mean = bench_data.mean() - _overhead
      _env.out.print("adjusted mean: " + mean.string() + " ns/iter\n")
    end

    _next_benchmark(consume bench_data)

  be _fail(name: String) =>
    _env.err.print("Failed benchmark: " + name)
    _env.exitcode(1)
