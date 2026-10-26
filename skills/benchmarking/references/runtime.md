# Runtime benchmarks

## Environment (step 3)

Record build flags, runtime, OS, CPU model, core count, memory, storage, and network. Run on the hardware the decision targets, and disclose when a candidate depends on features only some machines have, such as SVE, AVX-512, or a GPU. Before each session, check load with `uptime` and the core count with `nproc` (`sysctl -n hw.logicalcpu` on macOS).

## Harness (step 4)

- **Boundary:** time with a monotonic clock, and state where timing starts and stops. Separate setup, compilation or startup, warmup, measurement, and teardown. Report compilation or startup time apart from steady state whenever including it could flip the winner.
- **Work done:** force lazy results, await completion, and consume outputs so the compiler or runtime cannot drop the work. Measure cache hits and misses the way the workload declares them.
- **Resolution:** batch short operations until the timer resolves them, and measure harness overhead.
- **Timeouts:** a timed-out operation took an unknown time longer than its deadline. Label percentiles computed only from successes.

## Runs (step 6)

- **Steady state:** define warmup as an observable condition, such as stable throughput over declared windows. **Cold start:** reproduce the starting state before every run. Warm or reset each candidate separately.
- **Sustained claims:** run long enough to include GC, compaction, and checkpoints.
- **Profiling:** profile in separate runs, because profilers slow the work.
- **Latency:** report p50, p95, and p99 with sample counts. Compute percentiles from raw samples or merged histograms rather than averaging percentiles.

## Check the number (before step 7)

- **Limiter:** ask why the result isn't twice as fast, the first question of Brendan Gregg's [benchmarking checklist](https://www.brendangregg.com/methodology.html). Name the bounding resource from a profile or counters, and map it to source. When a change does not move the number, the limiter explains why.
- **Limits:** compare bytes per second with memory, disk, and network bandwidth, and compare operations per second times CPU cost per operation with the cores available. Time saved cannot exceed the time the changed piece took. A result past a limit means the run skipped work or hit a cache, or the estimate is wrong; find out which.
- **Prediction:** explain any large gap from step 1's prediction.
- **Share:** report a microbenchmark gain as a share of end-to-end time.
