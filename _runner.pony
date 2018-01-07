use "debug"
use "time"

actor _Runner
  let _ponybench: PonyBench

  // TODO make configurable
  let _max_iterations: U64 = 1_000_000_000
  let _sample_time: U64 = 100_000_000

  var _iterations: U64 = 1
  var _warmup: Bool = false
  var _start_cpu_time: U64 = 0
  var _name: String = ""

  new create(ponybench: PonyBench) =>
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    bench_data.results.clear()
    _iterations = 1
    _warmup = true
    _run(consume bench_data)

  fun ref _run(bench_data: _BenchData) =>
    bench_data.benchmark.before()
    _gc_next_behavior()
    _run_iteration(consume bench_data)

  be _run_iteration(bench_data: _BenchData, n: U64 = 0) =>
    if n == _iterations then
      let t' = Time.nanos()
      Time.perf_end()
      _complete(consume bench_data, t' - _start_cpu_time)
    else
      if n == 0 then
        Time.perf_begin()
        _start_cpu_time = Time.nanos()
      end
      try \likely\
        bench_data.benchmark()?
        _run_iteration(consume bench_data, n + 1)
      else
        _fail()
      end
    end

  fun ref _complete(bench_data: _BenchData, t: U64) =>
    bench_data.benchmark.after()
    if _warmup then
      match _calc_iterations(t)
      | let n: U64 => _iterations = n
      | None => _warmup = false
      end
      _run(consume bench_data)
    else
      bench_data.results.push(t)
      if bench_data.results.size() < bench_data.samples then
        _run(consume bench_data)
      else
        bench_data.iterations = _iterations
        _ponybench._complete(consume bench_data)
      end
    end

  fun ref _fail() =>
    _ponybench._fail(_name)

  fun ref _calc_iterations(total_runtime: U64): (U64 | None) =>
    let nspi = total_runtime / _iterations
    if (total_runtime < _sample_time) and (_iterations < _max_iterations) then
      var itrs' =
        if nspi == 0 then _max_iterations
        else _sample_time / nspi
        end
      itrs' = (itrs' + (itrs' / 5)).min(_iterations * 100).max(_iterations + 1)
      _round_up(itrs')
    else
      _iterations = _iterations.min(_max_iterations)
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
