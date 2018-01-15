# PonyBench (Version 2)

## Standard Output:

#### Pony Code
```pony
actor Main is BenchmarkList
  new create(env: Env) =>
    PonyBench(env, this)

  fun tag benchmarks(bench: PonyBench) =>
    bench(Fib(5))
    bench(Fib(10))
    bench(Fib(20))
    bench(Fib(40))

class iso Fib is MicroBenchmark
  let _n: U64

  new iso create(n: U64) =>
    _n = n

  fun name(): String =>
    "Fib(" + _n.string() + ")"

  fun apply() =>
    DoNotOptimise[U64](_fib(_n))
    DoNotOptimise.observe()

  fun _fib(n: U64): U64 =>
    if n < 2 then 1
    else _fib(n - 1) + _fib(n - 2)
    end
```

#### Output
```
$ ponyc -V0 --runtimebc examples/simple -b simple && ./simple --ponynoyield
Benchmark results will have their mean and median adjusted for overhead.
You may disable this with --noadjust.

Benchmark                                   mean            median   deviation  iterations
Fib(5)                                     15 ns             16 ns      ±0.11%     1000000
Fib(10)                                   180 ns            180 ns      ±0.55%      500000
Fib(20)                                 21525 ns          21511 ns      ±0.30%       10000
Fib(40)                             324952472 ns      324871552 ns      ±0.21%           1
```

## CSV Output

#### Output
```bash
$ ponyc -V0 --runtimebc examples/custom-config -b custom-config && ./custom-config --ponynoyield -csv > data.csv
```

#### Matlab Code (Visualization example)
```matlab
close all; clear; clc

M = csvread('data.csv',0,1);
M = M'; % transpose so that results are column vectors
overhead = median(M(:,1:2:end));
ops = M(:,2:2:end);
pows = 0:1:20;
sizes = 2.^pows;

%% box plot
boxplot(ops-overhead)
grid on
xticklabels('2^'+string(pows))
title('Persistent Vec Apply')
xlabel('size')
ylabel('runtime (ns)')
ax = gca;
ax.FontSize = 24;

%% histogram
figure
idxs = fliplr(5+1:5:21);
for i = idxs
    histogram(ops(:,i)-overhead(i))
    hold on
end
title('Histogram of Persistent Vec Apply (sizes 32^n)')
legend('size ' + string(sizes(idxs)))
xlabel('runtime (ns)')
ylabel('occurences')
ax = gca;
ax.FontSize = 24;
```

#### Charts
![alt text](https://github.com/Theodus/pony-benchmark/raw/master/examples/custom-config/charts/box.jpg)

![alt text](https://github.com/Theodus/pony-benchmark/raw/master/examples/custom-config/charts/hist.jpg)
