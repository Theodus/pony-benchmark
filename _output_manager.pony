use "term"

interface tag _OutputManager
  be apply(bench_data: _BenchData)

actor _TerminalOutput is _OutputManager
  let _env: Env
  let _ponybench: PonyBench
  var _overhead_mean: F64 = 0
  // var _overhead_median: U64 = 0

  new create(env: Env, ponybench: PonyBench) =>
    _env = env
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    let bench_data' =
      if bench_data.benchmark.name() == "PonyBench Overhead" then
        _overhead(consume bench_data)
      else
        _benchmark(consume bench_data)
      end

    _ponybench._next_benchmark(consume bench_data')

  fun ref _overhead(bench_data: _BenchData): _BenchData^ =>
    _overhead_mean = bench_data.mean()
    // _overhead_median = bench_data.median()
    let nspi = _overhead_mean / bench_data.iterations.f64()
    _print("overhead iters: " + bench_data.iterations.string())
    _print("overhead mean: "
      + _overhead_mean.string() + " ns, "
      + nspi.string() + " ns/iter")
    // _print("overhead median: " + _overhead_median.string() + " ns/iter")
    // _print("overhead standard deviation: " + bench_data.std_dev().string()  + " ns/iter")
    // if _overhead_mean > 50 then
    //   _warn("High overhead detected, benchmark measurements may be noisy (this may be a result of CPU scaling).")
    // end
    consume bench_data

  fun ref _benchmark(bench_data: _BenchData): _BenchData^ =>
    _heading(bench_data.benchmark.name())

    // let total_runtime = bench_data.sum()
    let iters = bench_data.iterations
    // let sum = bench_data.sum()
    let mean = bench_data.mean()
    // let median = bench_data.median()
    // let std_dev = bench_data.std_dev()

    _print("iterations: " + iters.string())
    let nspi = mean / bench_data.iterations.f64()
    _print("mean: " + mean.string() + " ns, " + nspi.string() + " ns/iter")

    // _print("total runtime: " + sum.string() + " ns")
    // _print("adjusted mean: " + (mean - _overhead_mean).string() + " ns/iter")
    // _print("adjusted median: " + (median - _overhead_median).string() + " ns/iter")
    // _print("standard deviation: " + bench_data.std_dev().string()  + " ns/iter")
    consume bench_data

  fun ref _heading(name: String) =>
    _print(ANSI.bold() + "\n---- Benchmark: " + name + ANSI.reset())

  fun ref _print(msg: String) =>
    _env.out.print(msg)

  fun ref _warn(msg: String) =>
    _print(ANSI.yellow() + ANSI.bold() + msg + ANSI.reset())

