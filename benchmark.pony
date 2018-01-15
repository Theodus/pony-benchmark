
type _Benchmark is
  ( MicroBenchmark
  | AsyncMicroBenchmark
  )

// interface iso _IBenchmark
//   fun box name(): String
//   fun box config(): BenchConfig
//   fun box overhead(): _IBenchmark^

interface iso MicroBenchmark
  fun box name(): String
  fun box config(): BenchConfig => BenchConfig
  fun box overhead(): MicroBenchmark^ => OverheadBenchmark
  fun ref before() => None
  // TODO document (single iteration!!)
  fun ref apply() ?
  fun ref after() => None

interface iso AsyncMicroBenchmark
  fun box name(): String
  fun box config(): BenchConfig => BenchConfig
  fun box overhead(): AsyncMicroBenchmark^ => AsyncOverheadBenchmark
  fun ref before(c: AsyncBenchContinue) => c.complete()
  // TODO document (single iteration!!)
  fun ref apply(c: AsyncBenchContinue) ?
  fun ref after(c: AsyncBenchContinue) => c.complete()

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

class iso AsyncOverheadBenchmark is AsyncMicroBenchmark
  fun name(): String =>
    "Benchmark Overhead"

  fun ref apply(c: AsyncBenchContinue) =>
    c.complete()
