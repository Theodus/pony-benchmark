use "collections"
use "debug" // TODO remove
use "time"

actor _Runner
  let _ponybench: PonyBench

  // TODO document and make configurable per-benchmark
  let _sample_time: U64 = 1_000_000_000
  let _max_iterations: U64 = 100_000

  var _warmup: Bool = true
  var _iterations: U64 = 0
  var _start_cpu_time: U64 = 0
  var _name: String = ""

  new create(ponybench: PonyBench) =>
    _ponybench = ponybench

  be apply(bench_data: _BenchData) =>
    _warmup = true
    _iterations = 1
    _name = bench_data.benchmark.name()

    bench_data.results.clear()
    _run(consume bench_data)

  fun ref _run(bench_data: _BenchData) =>
    bench_data.benchmark.before()
    _gc_next_behavior()
    _run_iteration(consume bench_data)

  be _run_iteration(bench_data: _BenchData, n: U64 = 0) =>
    if n == _iterations then
      _complete(consume bench_data)
    else
      try \likely\
        Time.perf_begin()
        let t = Time.nanos()
        bench_data.benchmark()?
        let t' = Time.nanos()
        Time.perf_end()
        // Debug([t; t'; t' - t])
        bench_data.results.push(t' - t)
      else
        _fail()
        return
      end
      _gc_next_behavior()
      _run_iteration(consume bench_data, n + 1)
    end

  fun ref _complete(bench_data: _BenchData) =>
    bench_data.benchmark.after()
    if _warmup then
      let total_runtime = bench_data.sum()
      match _calc_iterations(total_runtime)
      | let n: U64 => _iterations = n
      | None => _warmup = false
      end
      _run(consume bench_data)
    else
      bench_data.iterations = _iterations
      _ponybench._complete(consume bench_data)
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
