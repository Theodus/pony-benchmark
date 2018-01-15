use "collections"

// TODO bad things happen when this is val?
class iso _BenchData
  let benchmark: MicroBenchmark val
  let results: Array[U64]
  let iterations: U64

  new iso create(
    benchmark': MicroBenchmark,
    results': Array[U64] iso,
    iterations': U64)
  =>
    benchmark = consume benchmark'
    results = consume results'
    iterations = iterations'
    Sort[Array[U64], U64](results)

  fun raw_str(): String =>
    let str = recover String end
    str .> append(benchmark.name()) .> append(",")
    for n in results.values() do
      let nspi = n / iterations
      str .> append(nspi.string()) .> append(",")
    end
    if results.size() > 0 then try str.pop()? end end
    str

  fun sum(): U64 =>
    var sum': U64 = 0
    try
      for i in Range(0, results.size()) do
        sum' = sum' + results(i)?
      end
    end
    sum'

  fun mean(): F64 =>
    sum().f64() / results.size().f64()

  fun median(): F64 =>
    try
      let len = results.size()
      let i = len / 2
      if (len % 2) == 1 then
        results(i)?.f64()
      else
        (let lo, let hi) = (results(i)?, results(i + 1)?)
        ((lo.f64() + hi.f64()) / 2).round()
      end
    else
      0
    end

  fun std_dev(): F64 =>
    // sample standard deviation
    if results.size() < 2 then return 0 end
    try
      var sum_squares: F64 = 0
      for i in Range(0, results.size()) do
        let n = results(i)?.f64()
        sum_squares = sum_squares + (n * n)
      end
      let avg_squares = sum_squares / results.size().f64()
      let mean' = mean()
      let mean_sq = mean' * mean'
      let len = results.size().f64()
      ((len / (len - 1)) * (avg_squares - mean_sq)).sqrt()
    else
      0
    end
