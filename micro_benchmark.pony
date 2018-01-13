
interface iso MicroBenchmark
  fun box name(): String
  fun box config(): BenchConfig => BenchConfig
  fun ref before() => None
  fun ref apply() ? // TODO document (single iteration!!)
  fun ref after() => None

interface tag BenchmarkList
  fun tag overhead(): MicroBenchmark^ => OverheadBenchmark
  fun tag benchmarks(bench: PonyBench)

class val BenchConfig // TODO documentation
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
  fun name(): String => "PonyBench Overhead"

  fun ref apply() =>
    DoNotOptimise[None](None)
    DoNotOptimise.observe()
