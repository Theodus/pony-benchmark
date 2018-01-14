
interface iso MicroBenchmark
  fun box name(): String
  fun box config(): BenchConfig => BenchConfig
  fun box overhead(): MicroBenchmark^ => OverheadBenchmark
  fun ref before() => None
  // TODO document (single iteration!!)
  fun ref apply() ?
  fun ref after() => None

interface tag BenchmarkList
  fun tag benchmarks(bench: PonyBench)

// TODO documentation
class val BenchConfig
  let samples: USize
  let max_iterations: U64
  let max_sample_time: U64

  new val create(
    samples': USize = 20,
    max_iterations': U64 = 1_000_000_000,
    max_sample_time': U64 = 100_000_000)
  =>
    samples = samples'
    max_iterations = max_iterations'
    max_sample_time = max_sample_time'

class iso OverheadBenchmark is MicroBenchmark
  fun name(): String =>
    "Benchmark Overhead"

  fun ref apply() =>
    DoNotOptimise[None](None)
    DoNotOptimise.observe()
