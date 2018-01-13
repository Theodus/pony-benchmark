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

(TODO output to table)

#### Output
```bash
$ ponyc -V0 --runtimebc examples/simple -b simple && ./simple --ponynoyield

---- Benchmark: PonyBench Overhead
iterations          1000000
mean            2.15341e+08 ns,      215.341 ns/iter
adjusted mean             0 ns/iter
std. dev.       5.11845e+06 ns

---- Benchmark: Fib(5)
iterations          1000000
mean             2.1871e+08 ns,       218.71 ns/iter
adjusted mean       3.36864 ns/iter
std. dev.            372806 ns

---- Benchmark: Fib(10)
iterations           500000
mean            1.88764e+08 ns,      377.527 ns/iter
adjusted mean       162.186 ns/iter
std. dev.       2.09649e+06 ns

---- Benchmark: Fib(20)
iterations            10000
mean            2.17067e+08 ns,      21706.7 ns/iter
adjusted mean       21491.4 ns/iter
std. dev.            201038 ns

---- Benchmark: Fib(40)
iterations                1
mean            3.24522e+08 ns,  3.24522e+08 ns/iter
adjusted mean   3.24522e+08 ns/iter
std. dev.            190322 ns
```

## CSV Output

#### Output
```bash
$ ponyc -V0 --runtimebc examples/custom-config -b custom-config && ./custom-config --ponynoyield -csv > data.csv
```

(TODO use something more accessible than MATLAB for example)

#### Matlab Code (Visualization example)
```matlab
close all; clear; clc

M = csvread('data.csv');
M = M';
overhead = median(M(:,1));
ops = M(:,2:end);
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
idxs = fliplr(1+5:5:21);
for i = idxs
    histogram(ops(:,i)-overhead)
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
