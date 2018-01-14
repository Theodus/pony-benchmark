use "format"
use "term"

interface tag _OutputManager
  be apply(bench_data: _BenchData)

actor _TerminalOutput is _OutputManager
  let _env: Env
  let _ponybench: PonyBench
  let _noadjust: Bool
  var _overhead_mean: F64 = 0
  var _overhead_median: F64 = 0

  new create(env: Env, ponybench: PonyBench) =>
    _env = env
    _ponybench = ponybench
    _noadjust = _env.args.contains("--noadjust", {(a, b) => a == b })
    if not _noadjust then
      _print("Benchmark results will have their mean and median adjusted for overhead.")
      _print("You may disable this with --noadjust.\n")
    end
    _print_heading()

  be apply(bench_data: _BenchData) =>
    // _print(bench_data.raw_str())
    let bench_data' =
      if bench_data.benchmark.name() == "Benchmark Overhead" then
        _overhead_mean = bench_data.mean() / bench_data.iterations.f64()
        _overhead_median = bench_data.median() / bench_data.iterations.f64()
        consume bench_data
        // _print_benchmark(consume bench_data, false)
      else
        _print_benchmark(consume bench_data, not _noadjust)
      end
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
    _print("".join(
      [ ANSI.bold()
        Format("Benchmark" where width = 30)
        Format("mean" where width = 18, align = AlignRight)
        Format("median" where width = 18, align = AlignRight)
        Format("deviation" where width = 12, align = AlignRight)
        Format("iterations" where width = 12, align = AlignRight)
        ANSI.reset()
      ].values()))

  fun _print_result(
    name: String,
    mean: String,
    median: String,
    dev: String,
    iters: String)
  =>
    _print("".join(
      [ Format(name where width = 30)
        Format(mean + " ns" where width = 18, align = AlignRight)
        Format(median + " ns" where width = 18, align = AlignRight)
        Format("±" + dev + "%" where width = 13, align = AlignRight)
        Format(iters where width = 12, align = AlignRight)
      ].values()))

  fun _print(msg: String) =>
    _env.out.print(msg)

  fun _warn(msg: String) =>
    _print(ANSI.yellow() + ANSI.bold() + "Warning: " + msg + ANSI.reset())

// TODO document
// overhead, results...
// name, results...
actor _CSVOutput
  let _env: Env
  let _ponybench: PonyBench

  new create(env: Env, ponybench: PonyBench) =>
    _env = env
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    _print(bench_data.raw_str())
    _ponybench._next_benchmark(consume bench_data)

  fun _print(msg: String) =>
    _env.out.print(msg)
