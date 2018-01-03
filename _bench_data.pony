use "collections"

class iso _BenchData
  embed results: Array[U64] iso
  var iterations: U64
  var benchmark: MicroBenchmark

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

  fun ref median(): U64 =>
    try
      _sort(0, results.size().isize() - 1)?

      let len = results.size()
      let i = len / 2
      if (len % 2) == 1 then
        results(i)?
      else
        (let lo, let hi) = (results(i)?, results(i + 1)?)
        ((lo.f64() + hi.f64()) / 2.0).round().u64()
      end
    else
      0
    end

  fun ref std_dev(): U64 =>
    // sample standard deviation
    if results.size() < 2 then return 0 end
    try
      var sum_squares: U64 = 0
      for i in Range(0, results.size()) do
        let n = results(i)?
        sum_squares = sum_squares + (n * n)
      end
      let avg_squares = sum_squares.f64() / results.size().f64()
      let mean' = mean().f64()
      let mean_sq = mean' * mean'
      let len = results.size().f64()
      ((len / (len - 1.0)) * (avg_squares - mean_sq)).sqrt().u64()
    else
      0
    end

  fun ref _sort(lo: ISize, hi: ISize) ? =>
    // collections/Sort cannot be used on an iso Array
    if hi <= lo then return end
    // choose outermost elements as pivots
    if results(lo.usize())? > results(hi.usize())? then
      results.swap_elements(lo.usize(), hi.usize())?
    end
    (var p, var q) = (results(lo.usize())?, results(hi.usize())?)
    // partition according to invariant
    (var l, var g) = (lo + 1, hi - 1)
    var k = l
    while k <= g do
      if results(k.usize())? < p then
        results.swap_elements(k.usize(), l.usize())?
        l = l + 1
      elseif results(k.usize())? >= q then
        while (results(g.usize())? > q) and (k < g) do g = g - 1 end
        results.swap_elements(k.usize(), g.usize())?
        g = g - 1
        if results(k.usize())? < p then
          results.swap_elements(k.usize(), l.usize())?
          l = l + 1
        end
      end
      k = k + 1
    end
    (l, g) = (l - 1, g + 1)
    // swap pivots to final positions
    results.swap_elements(lo.usize(), l.usize())?
    results.swap_elements(hi.usize(), g.usize())?
    // recursively sort 3 partitions
    _sort(lo, l - 1)?
    _sort(l + 1, g - 1)?
    _sort(g + 1, hi)?
