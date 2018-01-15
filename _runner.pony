use "promises"
use "time"

// TODO async with something simpler than a promise

trait tag _Runner
  be apply()

actor _RunSync is _Runner
  let _ponybench: PonyBench
  embed _aggregator: _Aggregator
  let _name: String
  let _bench: MicroBenchmark
  var _start_cpu_time: U64 = 0

  new create(ponybench: PonyBench, benchmark: MicroBenchmark) =>
    _ponybench = ponybench
    _aggregator = _Aggregator(_ponybench, this, benchmark.config())
    _name = benchmark.name()
    _bench = consume benchmark
    apply()

  be apply() =>
    _bench.before()
    _gc_next_behavior()
    _run_iteration()

  be _run_iteration(n: U64 = 0) =>
    if n == _aggregator.iterations then
      let t' = Time.nanos()
      Time.perf_end()
      _complete(t' - _start_cpu_time)
    else
      if n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        _bench()?
        _run_iteration(n + 1)
      else
        _fail()
      end
    end

  be _complete(t: U64) =>
    _bench.after()
    _aggregator.complete(_name, t)

  be _fail() =>
    _ponybench._fail(_name)

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())

actor _RunAsync is _Runner
  let _ponybench: PonyBench
  embed _aggregator: _Aggregator
  let _name: String
  let _bench: AsyncMicroBenchmark ref
  var _start_cpu_time: U64 = 0

  new create(ponybench: PonyBench, benchmark: AsyncMicroBenchmark) =>
    _ponybench = ponybench
    _aggregator = _Aggregator(_ponybench, this, benchmark.config())
    _name = benchmark.name()
    _bench = consume benchmark
    apply()

  be apply() =>
    let t: _RunAsync tag = this
    _bench.before(
      Promise[None] .> next[None]({(_) => t._apply_cont() }))

  be _apply_cont() =>
    _gc_next_behavior()
    _run_iteration()

  be _run_iteration(n: U64 = 0) =>
    if n == _aggregator.iterations then
      let t' = Time.nanos()
      Time.perf_end()
      _complete(t' - _start_cpu_time)
    else
      if n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        let r: _RunAsync tag = this
        _bench(
          Promise[None] .> next[None]({(_) => r._run_iteration(n + 1) }))?
        // _run_iteration(n + 1)
      else
        _fail()
      end
    end

  be _complete(t: U64) =>
    let r: _RunAsync tag = this
    _bench.after(
      Promise[None] .> next[None]({(_) => r._complete_cont(t) }))

  be _complete_cont(t: U64) =>
    _aggregator.complete(_name, t)

  be _fail() =>
    _ponybench._fail(_name)

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())
