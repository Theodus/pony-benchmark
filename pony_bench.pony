
// TODO document that this is best used with
// --runtimebc and --ponynoyield

actor PonyBench
  let _env: Env
  let _output_manager: _OutputManager
  embed _bench_q: Array[MicroBenchmark] = Array[MicroBenchmark]
  let _runner: _Runner = _Runner(this)
  var _running: Bool = false

  new create(env: Env, list: BenchmarkList) =>
    _env = consume env
    _output_manager =
      if _env.args.contains("-csv", {(a, b) => a == b })
      then _CSVOutput(_env)
      else _TerminalOutput(_env)
      end

    list.benchmarks(this)

  be apply(bench: MicroBenchmark) =>
    _bench_q.push(bench.overhead())
    _bench_q.push(consume bench)
    if not _running then
      _running = true
      _next_benchmark()
    end

  be _next_benchmark() =>
    if _bench_q.size() > 0 then
      try
        _runner(_bench_q.shift()?)
      end
    else
      _running = false
    end

  be _complete(bench_data: _BenchData) =>
    _output_manager(consume bench_data)
    _next_benchmark()

  be _fail(name: String) =>
    _env.err.print("Failed benchmark: " + name)
    _env.exitcode(1)
