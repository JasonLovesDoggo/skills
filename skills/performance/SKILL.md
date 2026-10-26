---
name: performance
description: Make code faster with napkin math, a named limiter, and a hot-path checklist. Use when code is slow or must get faster, when estimating whether a design can meet a latency, throughput, or cost target, or when writing or reviewing code on a hot path.
---

# Performance

Find the **limiter**, make a **napkin math estimate**, and change the code so the hot path does less work, waits less, and keeps the hardware busy.

- **Limiter:** the one resource that binds right now: a core, memory bandwidth, the allocator or GC, a lock, disk, the network, a downstream service, or idle waiting.
- **Napkin math estimate:** the time the useful work should take on this hardware: each operation's count times its cost. The gap between it and the observed time says where to look.
- **Hot path:** code that runs once per request, record, or inner-loop iteration, so its cost multiplies.

Every speedup you report comes from a measurement. The `benchmarking` skill covers how to take one.

## Choose the path

- **Write:** new code that may run hot. Do step 1, then apply the [checklist](#hot-path-checklist) where the faster choice costs little readability.
- **Estimate:** a design, capacity, or cost question before the code exists. Do steps 1 and 2, then compare the alternatives against the target.
- **Optimize:** existing code is too slow. Do every step.
- **Review:** audit a diff or module. Do steps 1, 2, and 4 from the code and any supplied profile, then [report](#report) each finding with its estimated cost.

## 1. Scope the hot path

Decide how much complexity performance can earn here:

- **Setup, test, or one-shot code:** fix only the costs that break its time or resource budget.
- **Hot path:** the full checklist.
- **Library code:** callers decide how hot it gets, so take the cheap local wins: pre-sized containers, flat data structures, bulk APIs, and no per-call allocation.

Write the target: metric, current value, required value, and workload scale (input size, request rate, bytes, concurrency).

**Complete when:** the path, how often it runs or how much it processes, and the target are written down.

## 2. Do the napkin math

Make the napkin math estimate before you change anything. Read [references/napkin-math.md](references/napkin-math.md) for operation costs, derived rules, and worked examples, drawn from Simon Eskildsen's [napkin-math](https://github.com/sirupsen/napkin-math).

1. Decompose one unit of useful work into countable operations: bytes moved, passes over the data, allocations, syscalls, round trips, disk reads, lock acquisitions, and context switches.
2. Multiply each count by its cost and sum. For latency, sum sequential stages; take the maximum only for operations that fully overlap without competing for the same resource.
3. Keep units on every term, use at most six assumptions, and aim for the right order of magnitude.

Compare the estimate with the observed time:

- **Within 2–3x:** the estimate roughly explains the timing. Check measured resource use and look for avoidable work before calling the code hardware-bound.
- **10x or more:** time goes somewhere the model misses. Step 3 finds it.
- **Faster than the estimate:** the code skips work the model assumes, or the measurement missed work. Find out which before you trust either number.

**Complete when:** each candidate design or code path has an estimate with units, its dominant term, and the observed or target value next to it.

## 3. Find the limiter

Measure what binds, in runs you do not report, because profilers slow the work down:

- **CPU:** a sampling profiler for the runtime, such as `perf`, `pprof`, `py-spy`, `node --cpu-prof`, `async-profiler`, or Instruments. Note whether one core or all cores are busy.
- **Memory:** an allocation profile, GC logs, and hardware counters for cache misses.
- **Waiting:** an off-CPU or wall-clock profile, lock contention profiles, syscall counts (`strace -c`, `dtruss`), and query or RPC logs. Low CPU with high latency means the path is waiting.

Map the hot spot to source. Rank candidates by **Amdahl's law**: a piece taking fraction *p* of the time bounds the speedup from removing it at 1/(1 − *p*).

If the profile is flat, look higher up the stack. Find loops near the top of the flame graph, overly general code doing a simple job, and the largest source of allocations.

**Complete when:** the limiter is named with evidence (a profile, counters, or timings), and each top candidate carries its share of total time.

## 4. Interrogate the hot path

Ask every question in the [checklist](#hot-path-checklist) of the code the limiter points to. Answer with a count from the code or profile, such as passes over the data, allocations per item, calls per request, batch size, threads at peak, or time spent awaiting. For each change it suggests, record the estimated gain, using step 2's costs, and the trade-off.

**Complete when:** every question has a counted answer or "not applicable" with a reason, and every candidate change has an estimated gain and a trade-off.

## 5. Change and verify

Apply one change at a time. Try the groups in checklist order, because removing work usually beats doing it faster, but take a later change first when its estimated gain against its cost and risk is clearly larger. Stop as soon as the target is met. Keep each change behind an existing interface where you can. Check correctness, then measure against the step 1 target with the `benchmarking` skill.

Compare each measured gain with its estimate. A large miss in either direction means the model or the measurement is wrong; explain it before the next change. Revert changes whose measured gain does not pay for their complexity. Re-run step 3 after each kept change, because the limiter moves.

**Complete when:** the target is met, or further progress is blocked by a documented constraint, reported with the next change it would take. Every kept change has a measured before and after next to its estimate.

## Hot-path checklist

The groups follow Craig Hanson and Pat Crain's performance mantras, as listed in Brendan Gregg's [methodology](https://www.brendangregg.com/methodology.html).

### 1. Don't do it

- **Can it exit early?** Find where the answer is known before the work ends: first match, limit reached, cheap check failed. Run cheap predicates before expensive ones, add a fast path for the common case, and order searches so one result can make another unnecessary. *Trade-off:* each fast path is another branch to test.
- **Is it doing work nothing uses?** Find results nothing reads, validation repeated inside a module that its boundary already did, and stats, logging, or tracing on the hot path. Delete them, or sample the telemetry. *Trade-off:* less telemetry means less visibility.

### 2. Do it, but don't do it again

- **How many passes over the data? Can it take fewer?** Count full traversals per unit of work. Parse, validate, transform, and serialize as separate stages make four. Fuse stages into one scan, compute aggregates during an existing pass, and build structures in one shot from the whole input instead of one item at a time. *Trade-off:* fused code is harder to read and test.
- **Is it recomputing the same result?** Hoist loop invariants, precompute once, and cache repeated results with a clear invalidation rule. *Trade-off:* caches add memory, state, and staleness.

### 3. Do it less

- **How many I/O calls per unit of work? Can it make fewer?** Count syscalls, file opens, queries, RPCs, and round trips per request. Look for N+1 queries and per-item network calls. Batch through bulk APIs, multi-gets, `IN (...)`, and multi-row writes in one transaction. Buffer small writes and push filters and projections to the data source. *Trade-off:* bigger calls fail and retry as a unit.
- **Is it batching? How big are the batches?** Find the per-call overhead (round trip, transaction commit, syscall, lock acquisition, dispatch) and the per-item cost. Choose a size where the overhead is a small share of each batch, then cap it by memory, request size limits, timeouts, and time to first result. *Trade-off:* larger batches raise latency, peak memory, and the amount of work redone on failure.
- **How many allocations per item or request? Can it make fewer?** Count them from an allocation profile. Pre-size containers to their known size, reuse buffers and objects across iterations, and pass views, slices, or borrows rather than copies. Move rather than copy, sort indices rather than large records, and keep small collections inline or on the stack. GC cost depends on allocation rate, live data, and collector settings. *Trade-off:* reused buffers keep their peak size, so cap retained capacity and drop unusually large buffers.

### 4. Do it later

- **Can it wait until a caller needs it?** Defer expensive work to the first use, and compute stats on read rather than on every update. *Trade-off:* the first caller pays the cost, and errors surface later.

### 5. Do it when they're not looking

- **Is it idle while it awaits? What can run during the wait?** Find the critical path. Start independent work before awaiting: issue all requests and then await them, prefetch the next page while processing this one, and overlap compute with I/O. Move work that is off the critical path to the background or to build or startup time. *Trade-off:* speculative work wastes resources when its result goes unused.

### 6. Do it concurrently

- **Is it sequential? Can it run concurrently?** Find independent operations that run one after another: an `await` inside a loop, serial requests, stages that wait for the previous stage to finish everything. Run them together with the runtime's primitive (task group, `Promise.all`, `errgroup`, `asyncio.gather`), or pipeline the stages. Latency drops toward the slowest operation; total work stays the same. *Trade-off:* the operations must be independent, and errors, cancellation, and ordering get harder.
- **Should it stream instead?** Stream when the data exceeds the memory budget, when time to first result matters, or when downstream stages can start on early items. Batch when per-item overhead dominates. Chunked streams get both: stream items in batches sized as in group 3. *Trade-off:* streaming needs backpressure and mid-stream error handling, a global sort needs buffering or external storage, and exact dedupe needs state for every distinct item.
- **Can concurrency go higher? What does it cost?** Throughput rises until a resource saturates: cores, memory bandwidth, a connection pool, a lock, a downstream service, or a rate limit. Past that point latency and contention climb. By Little's law, at stable load, mean in-flight work = throughput × mean latency. Use that as the starting concurrency, then load-test it against throughput and tail latency. Bound concurrency explicitly with a pool or semaphore and sweep it to find the knee. *Trade-off:* each unit of concurrency costs memory and downstream load, and raises tail latency once anything saturates.
- **How many threads or tasks does it spawn? Too many or too few?** Count spawns per request and threads alive at peak against the core count. CPU-bound work wants about one thread per core. I/O-bound work needs enough in flight to cover latency, set by Little's law or by async I/O. Reuse a pool rather than spawning per item, run tiny work items inline, and give each worker a batch of items so scheduling overhead is amortized. *Trade-off:* oversubscription adds context switches, memory, and contention; undersubscription leaves cores idle.
- **What is shared, and for how long?** Measure time spent inside locks and contention on them. Keep I/O and expensive destructors out of critical sections, take a lock once per batch rather than once per item, shard contended structures that have no invariants spanning shards, and give each thread's hot mutable data its own cache line. *Trade-off:* sharding and lock-free structures are harder to get right; reach for them after measurement shows contention.

### 7. Do it cheaper

- **Is it the right data structure? How is the data laid out in memory?** Write the complexity of the dominant operation times N, and find hidden quadratics such as a linear search inside a loop. Prefer contiguous storage over one heap node per element: arrays and flat hash maps over linked lists, tree maps, and maps of maps. Use an array for a small integer key space, a bitset for a small-domain set, and indices for pointers. Keep fields accessed together close, move cold fields out of hot structs, and use the smallest type that fits. Use arenas for many objects that share a lifetime. *Trade-off:* compact layouts are harder to change; measure before bit-packing.
- **Is general code doing a simple job?** Replace it with specialized code for the common case, such as a prefix check rather than a regex. *Trade-off:* more code to maintain.

## Report

Lead with the answer to the target: met, not met, or impossible as specified. Then give the limiter and its evidence, the napkin math estimate next to the observed time, and each change with its estimated and measured gain and its trade-off. For a review, rank findings by estimated cost on the hot path and cite the code location. Mark estimates as estimates and measurements as measurements.
