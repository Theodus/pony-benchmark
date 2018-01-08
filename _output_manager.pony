use "format"
use "term"

interface tag _OutputManager
  be apply(bench_data: _BenchData)

// TODO CSV output

actor _TerminalOutput is _OutputManager
  let _env: Env
  let _ponybench: PonyBench
  var _overhead_mean: F64 = 0

  new create(env: Env, ponybench: PonyBench) =>
    _env = env
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    if bench_data.benchmark.name() == "PonyBench Overhead" then
      _overhead_mean = bench_data.mean()
    end

    let bench_data' = _print_benchmark(consume bench_data)
    _ponybench._next_benchmark(consume bench_data')


  fun ref _print_benchmark(bench_data: _BenchData): _BenchData^ =>
    _print_heading(bench_data.benchmark.name())

    let iters = bench_data.iterations
    // let samples = bench_data.samples

    let mean = bench_data.mean()
    let nspi = mean / iters.f64()

    let mean' = mean - _overhead_mean
    let nspi' = mean' / iters.f64()

    _print("iterations     "
      + Format.int[U64](iters where width = 12))
    _print("mean           "
      + Format.float[F64](mean where width = 12) + " ns, "
      + Format.float[F64](nspi where width = 12) + " ns/iter")
    _print("adjusted mean  "
      + Format.float[F64](mean' where width = 12) + " ns, "
      + Format.float[F64](nspi' where width = 12) + " ns/iter")

    consume bench_data

  fun _print_heading(name: String) =>
    _print(ANSI.bold() + "\n---- Benchmark: " + name + ANSI.reset())

  fun _print(msg: String) =>
    _env.out.print(msg)

  fun _warn(msg: String) =>
    _print(ANSI.yellow() + ANSI.bold() + msg + ANSI.reset())

