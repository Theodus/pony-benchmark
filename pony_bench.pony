
actor PonyBench
  let _env: Env
  let _output_manager: _OutputManager
  embed _bench_q: Array[MicroBenchmark] = Array[MicroBenchmark]
  let _runner: _Runner = _Runner(this)
  var _running: Bool = false

  new create(env: Env, list: BenchmarkList) =>
    _env = consume env
    let bench_data = _BenchData.overhead(list.overhead())
    _output_manager =
      if _env.args.contains("-csv", {(a, b) => a == b })
      then _CSVOutput(_env, this)
      else _TerminalOutput(_env, this, bench_data.benchmark)
      end
    _running = true
    _runner(consume bench_data)

    list.benchmarks(this)

  be apply(bench: MicroBenchmark) =>
    _bench_q.push(consume bench)

  be _next_benchmark(bench_data: _BenchData) =>
    if _bench_q.size() > 0 then
      try
        bench_data.reset(_bench_q.shift()?)
        _runner(consume bench_data)
      end
    else
      _running = false
    end

  be _complete(bench_data: _BenchData) =>
    _output_manager(consume bench_data)

  be _fail(name: String) =>
    _env.err.print("Failed benchmark: " + name)
    _env.exitcode(1)
