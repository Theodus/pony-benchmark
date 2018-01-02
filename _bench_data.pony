use "collections"

class iso _BenchData
  embed results: Array[U64] iso
  var iterations: U64
  var benchmark: MicroBenchmark

  // new iso null() =>
  //   results = recover Array[U64](100_000) end
  //   iterations = 0
  //   benchmark = _NullBenchmark

  new iso overhead() =>
    results = recover Array[U64](100_000) end
    iterations = 0
    benchmark = _OverheadBenchmark

  fun ref reset(benchmark': MicroBenchmark) =>
    benchmark = consume benchmark'
    iterations = 0

  fun ref sum(): U64 =>
    var sum': U64 = 0
    try
      for i in Range(0, results.size()) do
        sum' = sum' + results(i)?
      end
    end
    sum'

  fun ref mean(): U64 =>
    sum() / results.size().u64()
