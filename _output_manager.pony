use "format"
use "term"

interface tag _OutputManager
  be apply(bench_data: _BenchData)

actor _TerminalOutput is _OutputManager
  let _env: Env
  let _ponybench: PonyBench
  let _overhead_id: MicroBenchmark tag
  let _noadjust: Bool
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
    _noadjust = _env.args.contains("--noadjust", {(a, b) => a == b })
    if not _noadjust then
      _print("Benchmark results will have their mean and median adjusted for overhead.")
      _print("You may disable this with --noadjust.\n")
    end
    _print_heading()

  be apply(bench_data: _BenchData) =>
    // TODO optional adjustment (possible warning for high dev)
    var adjust = not _noadjust
    if bench_data.benchmark is _overhead_id then
      _overhead_mean = bench_data.mean() / bench_data.iterations.f64()
      _overhead_median = bench_data.median() / bench_data.iterations.f64()
      adjust = false
    end

    let bench_data' = _print_benchmark(consume bench_data, adjust)
    _ponybench._next_benchmark(consume bench_data')

  fun ref _print_benchmark(
    bench_data: _BenchData,
    adjust: Bool)
    : _BenchData^
  =>
    let iters = bench_data.iterations.f64()
    let mean' = bench_data.mean()
    var mean = mean' / iters
    var median = bench_data.median() / iters
    // TODO check for negative results from adjustment
    if adjust then
      mean = mean - _overhead_mean
      median =  median - _overhead_median
    end

    let std_dev = bench_data.std_dev()
    let relative_std_dev = (std_dev * 100) / mean'

    _print_result(
      bench_data.benchmark.name(),
      mean.round().i64().string(),
      median.round().i64().string(),
      Format.float[F64](relative_std_dev where prec = 2, fmt = FormatFix),
      iters.u64().string())

    if (mean.round() < 0) or (median.round() < 0) then
      _warn("Adjustment for overhead has resulted in negative values.")
    end

    consume bench_data

  fun _print_heading() =>
    _print(
      ANSI.bold()
      + Format("Benchmark" where width = 30)
      + Format("mean" where width = 18, align = AlignRight)
      + Format("median" where width = 18, align = AlignRight)
      + Format("deviation" where width = 12, align = AlignRight)
      + Format("iterations" where width = 12, align = AlignRight)
      + ANSI.reset())

  fun _print_result(
    name: String,
    mean: String,
    median: String,
    dev: String,
    iters: String)
  =>
    _print(
      Format(name where width = 30)
      + Format(mean + " ns" where width = 18, align = AlignRight)
      + Format(median + " ns" where width = 18, align = AlignRight)
      + Format("±" + dev + "%" where width = 13, align = AlignRight)
      + Format(iters where width = 12, align = AlignRight))

  fun _print(msg: String) =>
    _env.out.print(msg)

  fun _warn(msg: String) =>
    _print(ANSI.yellow() + ANSI.bold() + "Warning: " + msg + ANSI.reset())

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
