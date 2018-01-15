
// TODO document that this is best used with
// --runtimebc and --ponynoyield

actor PonyBench
  let _env: Env
  let _output_manager: _OutputManager
  embed _bench_q: Array[_Benchmark] = Array[_Benchmark]
  var _running: Bool = false

  new create(env: Env, list: BenchmarkList) =>
    _env = consume env
    _output_manager =
      if _env.args.contains("-csv", {(a, b) => a == b })
      then _CSVOutput(_env)
      else _TerminalOutput(_env)
      end

    list.benchmarks(this)

  be apply(bench: _Benchmark) =>
    // TODO this is ugly and it makes me sad,
    // but an F-bounded polymorphic interface and a union
    // don't get along well in an intersection type.
    match consume bench
    | let b: MicroBenchmark =>
      _bench_q.push(b.overhead())
      _bench_q.push(consume b)
    | let b: AsyncMicroBenchmark =>
      _bench_q.push(b.overhead())
      _bench_q.push(consume b)
    end

    if not _running then
      _running = true
      _next_benchmark()
    end

  be _next_benchmark() =>
    if _bench_q.size() > 0 then
      try
        match _bench_q.shift()?
        | let b: MicroBenchmark => _RunSync(this, consume b)
        | let b: AsyncMicroBenchmark => _RunAsync(this, consume b)
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
