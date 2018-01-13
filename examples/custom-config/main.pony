use "collections"
use p = "collections/persistent"
use "random"
use "time"
use "../.."

actor Main is BenchmarkList
  new create(env: Env) =>
    PonyBench(env, this)

  fun tag overhead(): MicroBenchmark^ =>
    BenchOverhead

  fun tag benchmarks(bench: PonyBench) =>
    for n in Range(0, 21) do
      bench(BenchApply(1 << n))
    end

class iso BenchOverhead is MicroBenchmark
  embed _rand: Rand

  new iso create() =>
    _rand = Rand(Time.millis())

  fun name(): String => "Benchmark Overhead"

  fun ref apply() =>
    DoNotOptimise[USize](_rand.usize())
    DoNotOptimise.observe()

class iso BenchApply is MicroBenchmark
  let _size: USize
  var _p: p.Vec[U64] = p.Vec[U64]
  embed _rand: Rand

  new iso create(size: USize) =>
    _size = size
    _rand = Rand(Time.millis())

  fun name(): String =>
    "apply " + _size.string()

  fun config(): BenchConfig =>
    BenchConfig(where
      samples' = 20,
      max_sample_time' = 200_000_000)

  fun ref before() =>
    _p = p.Vec[U64]
    for i in Range(0, _size) do _p = _p.push(i.u64()) end

  fun ref apply() ? =>
    let i = _rand.int[USize](_size)
    DoNotOptimise[U64](_p(i)?)
    DoNotOptimise.observe()
