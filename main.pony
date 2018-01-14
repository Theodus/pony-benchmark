
actor Main is BenchmarkList
  new create(env: Env) =>
    PonyBench(env, this)

  fun tag benchmarks(bench: PonyBench) =>
    bench(_Fib(10))
    bench(_Fib(20))
    bench(_Fib(5))
    bench(_Nothing)
    bench(_Fib(5))
    bench(_Fib(10))
    bench(_Fib(20))
    bench(_Fib(40))

class iso _Nothing is MicroBenchmark
  fun name(): String => "Nothing"

  fun apply() =>
    DoNotOptimise[None](None)
    DoNotOptimise.observe()

class iso _Fib is MicroBenchmark
  let _n: U64

  new iso create(n: U64) =>
    _n = n

  fun name(): String =>
    "_Fib(" + _n.string() + ")"

  fun apply() =>
    DoNotOptimise[U64](_fib(_n))
    DoNotOptimise.observe()

  fun _fib(n: U64): U64 =>
    if n < 2 then 1
    else _fib(n - 1) + _fib(n - 2)
    end
