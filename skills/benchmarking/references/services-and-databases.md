# Service and database reference

## Placement and generator capacity

Choose client placement from the measurement boundary. A separate generator host can isolate server resources, but its network path contributes to end-to-end latency. Record region/zone, topology, round-trip latency, connection setup/reuse, TLS, pooling, and connection limits. For same-host tests, account for client/server contention.

With sequential requests, no pipelining, and negligible client work, per-connection throughput is approximately `1 / (network RTT + server processing time)`. Use this as a diagnostic bound, not a model for queued or multiplexed systems. Equal connection counts can produce different server load on different network paths.

Validate generator capacity at the intended rate using CPU, scheduler/event-loop lag, connection limits, in-flight work, queues, and network capacity. Quiet CPU alone does not establish capacity. Resolve generator saturation before claiming server capacity; otherwise label the result generator-limited.

## Arrival model and overload

Match the load model to the question and actual backpressure:

| Model | Scheduling | Question |
| --- | --- | --- |
| Closed loop | Each worker waits for completion before its next operation | What do a fixed number of workers achieve? |
| Open loop | Arrivals follow an independent schedule or replayed trace | What happens at specified external demand, including overload? |

In a closed loop, stalls reduce subsequent offered load. This can cause coordinated omission when interpreted as latency under independent arrivals: requests that would have queued were never issued. Label the measurement accordingly. Prefer directly measuring the intended model; disclose assumptions behind any statistical correction.

For open-loop load, schedule against a monotonic deadline independent of response completion. Awaiting a response and then sleeping is closed loop. Record intended arrival, actual dispatch, and completion times where feasible. Separate scheduler delay, client-observed response time, and time from intended arrival to completion; state which boundary supports the claim.

Define behavior when concurrency or queue limits are reached: queue, reject, drop, or stop according to a declared bound. Count intended, submitted, completed, failed, timed-out, dropped, and pending work as applicable. Expose backpressure and missed schedules; nominal target rate does not prove the server received that load.

For capacity claims, sweep offered load or concurrency through the relevant range and report successful throughput against latency and errors. Define sustainable capacity by the stated latency/error constraint and queue stability. Specify when arrivals stop and in-flight work drains or times out. Count completions over their actual measurement interval, including any reported drain interval.

## Working set and database semantics

Record total rows/bytes, indexes, payload/result sizes, active working set, key distribution, hot-key/tenant skew, read/write mix, transaction boundaries, isolation, and batch size. Keep queries semantically equivalent; inspect plans and schema/index differences when they explain performance.

Compare working set with effective cache capacity, including database buffers, OS page cache, indexes, and metadata. Treat RAM-resident, I/O-bound, and skewed-access cases as distinct workloads. Verify cache/I/O behavior where observable; dataset size alone does not prove residency.

Record acknowledgment, commit, replication, and persistence guarantees, including fsync/WAL settings or equivalents. Measure completed transactions separately from statements. Specify whether connection acquisition, retries, and commit acknowledgments fall inside timing.

## Background work and reset

Inspect checkpoint/WAL thresholds, autovacuum, compaction, GC, storage burst credits, replication, and relevant maintenance. Choose intervals that observe their effects for sustained-performance claims; disclose missing cycles as limitations.

Match behavior and guarantees across systems, because equal parameter values can behave differently.

Restore data and cache conditions for each declared trial state, accounting for growth, fragmentation, and mutation. Define which layers a cold reset affects: process state, database buffers, OS cache, or remote/storage caches. Record inaccessible layers as uncontrolled; a process restart alone does not demonstrate cold storage.
