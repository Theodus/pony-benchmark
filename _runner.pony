use "time"

actor _Runner
  let _ponybench: PonyBench
  var _config: BenchConfig = BenchConfig
  var _samples: Array[U64] iso = recover [] end
  var _iterations: U64 = 1
  var _warmup: Bool = false
  var _start_cpu_time: U64 = 0
  var _name: String = ""

  new create(ponybench: PonyBench) =>
    _ponybench = ponybench

  be apply(benchmark: MicroBenchmark) =>
    _config = benchmark.config()
    _samples = recover Array[U64](_config.samples) end
    _iterations = 1
    _warmup = true
    _name = benchmark.name()
    _run(consume benchmark)

  fun ref _run(benchmark: MicroBenchmark) =>
    benchmark.before()
    _gc_next_behavior()
    _run_iteration(consume benchmark)

  be _run_iteration(benchmark: MicroBenchmark, n: U64 = 0) =>
    if n == _iterations then
      let t' = Time.nanos()
      Time.perf_end()
      _complete(consume benchmark, t' - _start_cpu_time)
    else
      if n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        benchmark()?
        _run_iteration(consume benchmark, n + 1)
      else
        _fail()
      end
    end

  fun ref _complete(benchmark: MicroBenchmark, t: U64) =>
    benchmark.after()
    if _warmup then
      match _calc_iterations(t)
      | let n: U64 => _iterations = n
      | None => _warmup = false
      end
      _run(consume benchmark)
    else
      _samples.push(t)
      if _samples.size() < _config.samples then
        _run(consume benchmark)
      else
        _ponybench._complete(_Results(
          consume benchmark,
          _samples = recover [] end,
          _iterations))
      end
    end

  fun ref _fail() =>
    _ponybench._fail(_name)

  fun ref _calc_iterations(total_runtime: U64): (U64 | None) =>
    let max_i = _config.max_iterations
    let max_t = _config.max_sample_time
    let nspi = total_runtime / _iterations
    if (total_runtime < max_t) and (_iterations < max_i) then
      var itrs' =
        if nspi == 0 then max_i
        else max_t / nspi
        end
      itrs' = (itrs' + (itrs' / 5)).min(_iterations * 100).max(_iterations + 1)
      _round_up(itrs')
    else
      _iterations = _iterations.min(max_i)
      None
    end

  fun ref _round_up(x: U64): U64 =>
    """
    Round x up to a number of the form [1^x, 2^x, 3^x, 5^x].
    """
    let base = _round_down_10(x)
    if x <= base then
      base
    elseif x <= (base * 2) then
      base * 2
    elseif x <= (base * 3) then
      base * 3
    elseif x <= (base * 5) then
      base * 5
    else
      base * 10
    end

  fun _round_down_10(x: U64): U64 =>
    """
    Round down to the nearest power of 10.
    """
    let tens = x.f64().log10().floor()
    F64(10).pow(tens).u64()

  fun ref _gc_next_behavior() =>
    @pony_triggergc[None](@pony_ctx[Pointer[None]]())
