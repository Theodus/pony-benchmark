
interface iso MicroBenchmark
  fun box name(): String
  fun ref before() => None
  fun ref apply() ? // TODO document (single iteration!!)
  fun ref after() => None

interface tag BenchmarkList
  fun tag benchmarks(bench: PonyBench)

class iso _OverheadBenchmark is MicroBenchmark
  fun name(): String => "overhead"

  fun ref apply() =>
    DoNotOptimise[None](None)
    DoNotOptimise.observe()
