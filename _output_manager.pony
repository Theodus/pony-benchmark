use "format"
use "term"

interface tag _OutputManager
  be apply(bench_data: _BenchData)

actor _TerminalOutput is _OutputManager
  let _env: Env
  let _ponybench: PonyBench
  let _overhead_id: MicroBenchmark tag
  var _overhead_mean: F64 = 0
  var _overhead_median: F64 = 0

  new create(
    env: Env,
    ponybench: PonyBench,
    overhead_id: MicroBenchmark tag)
  =>
    _env = env
    _ponybench = ponybench
    _overhead_id = overhead_id

    _print_heading()

  be apply(bench_data: _BenchData) =>
    if bench_data.benchmark is _overhead_id then
      _overhead_mean = bench_data.mean() / bench_data.iterations.f64()
      _overhead_median = bench_data.median() / bench_data.iterations.f64()
    end

    let bench_data' = _print_benchmark(consume bench_data)
    _ponybench._next_benchmark(consume bench_data')


  fun ref _print_benchmark(bench_data: _BenchData): _BenchData^ =>
    let iters = bench_data.iterations.f64()
    // TODO optional adjustment (possible warning for high dev)
    // TODO check for negative results from adjustment
    let mean = (bench_data.mean() / iters) - _overhead_mean
    let median = (bench_data.median() / iters) - _overhead_median
    _print_result(
      bench_data.benchmark.name(),
      mean.round().u64().string(),
      median.round().u64().string(),
      Format.float[F64](bench_data.std_dev() / iters
        where prec = 2, fmt = FormatFix))

    consume bench_data

  fun _print_heading() =>
    _print(
      ANSI.bold()
      + Format("Benchmark" where width = 30)
      + Format("mean" where width = 16, align = AlignRight)
      + Format("median" where width = 16, align = AlignRight)
      + Format("deviation" where width = 16, align = AlignRight)
      + ANSI.reset())

  fun _print_result(name: String, mean: String, median: String, dev: String) =>
    _print(
      Format(name where width = 30)
      + Format(mean + " ns" where width = 16, align = AlignRight)
      + Format(median + " ns" where width = 16, align = AlignRight)
      + Format("±" + dev + "%" where width = 17, align = AlignRight))

  fun _print(msg: String) =>
    _env.out.print(msg)

  fun _warn(msg: String) =>
    _print(ANSI.yellow() + ANSI.bold() + msg + ANSI.reset())

actor _CSVOutput
  let _env: Env
  let _ponybench: PonyBench

  new create(env: Env, ponybench: PonyBench) =>
    _env = env
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    // TODO include benchmark name
    _print(bench_data.raw_str())
    _ponybench._next_benchmark(consume bench_data)

  fun _print(msg: String) =>
    _env.out.print(msg)
