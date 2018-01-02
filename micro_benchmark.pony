
interface iso MicroBenchmark
  fun box name(): String
  fun ref before() => None
  fun ref apply() ? // TODO document (single iteration!!)
  fun ref after() => None

interface tag BenchmarkList
  fun tag benchmarks(bench: PonyBench)

class iso _BenchData
  embed results: Array[U64] iso
  var iterations: U64
  var benchmark: MicroBenchmark

  new iso overhead() =>
    results = recover Array[U64] end
    iterations = 0
    benchmark = _OverheadBenchmark

  fun ref reset(benchmark': MicroBenchmark) =>
    benchmark = consume benchmark'
    iterations = 0

class iso _OverheadBenchmark is MicroBenchmark
  fun name(): String => "ponybench overhead"

  fun ref apply() =>
    DoNotOptimise[None](None)
    DoNotOptimise.observe()
