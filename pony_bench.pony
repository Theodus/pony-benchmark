use "collections" // TODO remove

actor PonyBench
  let _env: Env
  embed _bench_q: Array[MicroBenchmark] = Array[MicroBenchmark]
  let _runner: _Runner = _Runner(this)
  var _running: Bool = false
  var _overhead_mean: U64 = 0

  new create(env: Env, list: BenchmarkList) =>
    _env = env
    _overhead_benchmark()
    list.benchmarks(this)

  be apply(bench: MicroBenchmark) =>
    _bench_q.push(consume bench)

  fun ref _overhead_benchmark() =>
    // Kick off the first benchmark as a measure of overhead
    _env.out.print("Calculating overhead...")
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
    if bench_data.benchmark.name() == "ponybench overhead" then
      let len = bench_data.results.size()
      let iters = bench_data.iterations
      try _overhead_mean = (bench_data.results(0)? / iters) end
      for i in Range(0, len) do
        try
          let n = bench_data.results(i)?
          _env.out.print("ns/iter: " + (n / iters).string() + "ns/iter")
        end
      end
    else
      _env.out.print(bench_data.benchmark.name() + " complete.")
      let len = bench_data.results.size()
      let iters = bench_data.iterations
      _env.out.print("iterations: " + iters.string())
      for i in Range(0, len) do
        try
          let n = bench_data.results(i)?
          // _env.out.print("runtime: " + n.string() + "ns")
          let nspi = n / iters
          // _env.out.print("ns/iter: " + nspi.string() + "ns/iter")
          _env.out.print("adjusted: " + (nspi - _overhead_mean).string() + "ns/iter")
        end
      end
    end
    _next_benchmark(consume bench_data)

  be _fail(name: String) =>
    _env.err.print("Failed benchmark: " + name)
    _env.exitcode(1)
