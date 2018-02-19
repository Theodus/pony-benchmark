
// TODO document that this is best used with
// --runtimebc and --ponynoyield

// TODO print "no benchmarks found" if no benchmarks.

actor PonyBench
  let _env: Env
  let _output_manager: _OutputManager
  embed _bench_q: Array[(Benchmark, Bool)] = Array[(Benchmark, Bool)]
  var _running: Bool = false

  new create(env: Env, list: BenchmarkList) =>
    _env = consume env
    ifdef debug then
      _env.err.print("***WARNING*** Benchmark was built as DEBUG. Timings may be affected.")
    end

    _output_manager =
      if _env.args.contains("-csv", {(a, b) => a == b })
      then _CSVOutput(_env)
      else _TerminalOutput(_env)
      end

    list.benchmarks(this)

  be apply(bench: Benchmark) =>
    match consume bench
    | let b: MicroBenchmark =>
      _bench_q.push((b.overhead(), true))
      _bench_q.push((consume b, false))
    | let b: AsyncMicroBenchmark =>
      _bench_q.push((b.overhead(), true))
      _bench_q.push((consume b, false))
    end

    if not _running then
      _running = true
      _next_benchmark()
    end

  be _next_benchmark() =>
    if _bench_q.size() > 0 then
      try
        match _bench_q.shift()?
        | (let b: MicroBenchmark, let overhead: Bool) =>
          _RunSync(this, consume b, overhead)
        | (let b: AsyncMicroBenchmark, let overhead: Bool) =>
          _RunAsync(this, consume b, overhead)
        end
      end
    else
      _running = false
    end

  be _complete(results: _Results) =>
    _output_manager(consume results)
    _next_benchmark()

  be _fail(name: String) =>
    _env.err.print("Failed benchmark: " + name)
    _env.exitcode(1)
