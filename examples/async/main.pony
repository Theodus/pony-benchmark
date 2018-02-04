use "../.."
use "promises"

actor Main is BenchmarkList
  new create(env: Env) =>
    PonyBench(env, this)

  fun tag benchmarks(bench: PonyBench) =>
    bench(_Fib(5))
    bench(_Fib(10))
    bench(_Fib(20))

class iso _Fib is AsyncMicroBenchmark
  let _f: _FibActor
  let _name: String

  new iso create(n: USize) =>
    _f = _FibActor(n)
    _name = "_Fib(" + n.string() + ")"

  fun name(): String =>
    _name

  fun config(): BenchConfig =>
    BenchConfig(where
      samples' = 100,
      max_sample_time' = 1_000_000)

  fun apply(c: AsyncBenchContinue) =>
    _f(Promise[USize]
      .> next[None]({(n) => c.complete() }))

actor _FibActor
  let _n: USize

  new create(n: USize) =>
    _n = n

  be apply(p: Promise[USize]) =>
    p(_fib(_n))

  fun _fib(n: USize): USize =>
    if n < 2 then 1
    else _fib(n - 1) + _fib(n - 2)
    end
