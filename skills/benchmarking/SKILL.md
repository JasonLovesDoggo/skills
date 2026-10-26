---
name: benchmarking
description: Design, implement, run, and review software performance benchmarks. Use when writing a benchmark harness, comparing implementations, configurations, or services, reporting a measured speedup or regression, or auditing benchmark methodology and claims.
---

# Benchmarking

Make each benchmark answer a specific engineering question with controlled comparisons and reproducible evidence.

## Choose the path

- **Design:** produce the experiment specification and execution plan.
- **Implement or run:** follow the workflow through the requested deliverable; identify which commands actually ran.
- **Review:** audit the workflow against supplied code, configuration, and results. Report evidence, its impact on the conclusion, and a concrete remedy. Treat missing evidence as unknown; execution is optional unless requested.

For client/server systems or databases, read [references/services-and-databases.md](references/services-and-databases.md) before choosing or auditing the workload and harness.

## 1. Define the experiment

Inspect the relevant implementation and existing benchmark tooling. Write a compact specification:

- **Question:** the decision the result will inform and the systems, versions, or configurations compared.
- **Useful work:** the operation and its correctness criterion. Distinguish a request, query, transaction, and batch.
- **Boundary:** where timing starts and ends; identify included setup, serialization, I/O, retries, and cleanup.
- **Workload:** input provenance or generation, seeds, sizes, operation mix, access distribution, and concurrency or arrival rate. Label synthetic stress cases and what they exercise.
- **Decision rule:** primary metric, relevant constraints, minimum meaningful improvement or regression, and stopping rule.
- **Prediction:** a napkin-math estimate of each candidate's result and its expected limiter, from the `performance` skill. A result far from the prediction is investigated before it is reported.

Choose representative cases and useful boundaries, such as typical inputs, large inputs, and contention. Keep the matrix focused. Vary one factor for causal isolation; label experiments that change several factors together. Set the decision rule before examining comparative results.

**Complete when:** the question, workload matrix, measurement boundary, decision rule, and prediction are explicit enough to implement without guessing.

## 2. Control the comparison

Require equivalent useful work and relevant guarantees: correctness, precision, durability, consistency, replication, and failure handling. Record tradeoffs when these differ.

Choose the comparison basis: same resources, same cost, shipped defaults, or separately tuned systems. Apply that policy symmetrically. Different architectures can be valid candidates for an application decision; scope the conclusion to that decision and workload.

Record software versions or commits, build mode and flags, runtime, OS, CPU model/generation, available cores, memory, storage, network placement, and effective configuration. Match the dimensions relevant to the question. Core count and RAM alone do not establish equivalent hardware. Mark unavailable platform details as unknown.

Control competing work, resource limits, power or thermal state, and input state where relevant. Disclose unavoidable differences. Record prices and their date when cost is part of the comparison.

**Complete when:** each material difference is controlled, intentionally varied, or disclosed, and each candidate satisfies the stated correctness and service contract.

## 3. Validate the harness

Use the repository's established benchmark framework when suitable. Make inputs, duration, repetition, and output location configurable through its conventions.

- Verify representative outputs against an oracle or invariant. Keep validation outside the timed region unless it belongs to the operation; retain a way to detect incorrect or failed work during measurement.
- Use a monotonic clock for elapsed time. State units and timing boundaries. For asynchronous work, measure completion at the chosen boundary, including required synchronization.
- For short operations, batch enough work to resolve timer granularity and inspect harness overhead. Keep fixture construction, logging, and unrelated allocation outside the boundary unless the question includes them.
- For compiled or JIT code, consume results and use inputs that exercise real work. Check for constant folding and dead-code elimination while retaining representative runtime optimization.
- Separate setup, warmup, measurement, and teardown. Reset mutable state according to the experiment.
- Account for attempted, successful, failed, timed-out, retried, and unfinished work as applicable. Specify retry and timeout policy. Distinguish useful completions from attempts.

Run a small correctness smoke test. Check counts, units, outputs, and telemetry before collecting performance evidence; label smoke-test output accordingly.

**Complete when:** the harness performs the intended work, measures the intended interval, accounts for outcomes, and exposes overhead or scheduling limits that could dominate the result.

## 4. Establish the execution protocol

Choose the state being measured:

- **Steady state:** define an observable warmup criterion, such as stable throughput and latency across declared windows plus relevant cache/JIT readiness. Bound warmup; label failure to stabilize.
- **Cold start, recovery, or cache misses:** define and reproduce the intended starting state for every trial; include the startup costs the question asks about.

Choose measurement duration from sample needs and relevant background cycles: GC, checkpointing, compaction, autoscaling, or maintenance. Use a shorter observation only with an explicit limit on what it can establish.

Repeat independent trials with a declared reset policy. Alternate or randomize candidate order to reduce drift; record order and environment changes. Choose repetition and stopping criteria from pilot variability and the decision's stakes. Keep exploratory tuning separate from final comparisons. Preserve failed or excluded trials and their reasons.

**Complete when:** starting state, warmup, measurement interval, repetition, ordering, reset policy, and stopping criteria are reproducible and support the claimed operating condition.

## 5. Collect and summarize evidence

Select metrics appropriate to the question:

| Work | Primary observations |
| --- | --- |
| Service or database | Successful throughput, latency distribution, errors/timeouts, offered load, and queue behavior |
| Function or microbenchmark | Time per operation or operations per second; allocations or memory when relevant |
| Batch job or startup | Total elapsed time, work completed, resource use, and completion/failure status |

Retain raw samples or mergeable histograms, per-run summaries, counts, and timestamps. Capture CPU, memory/GC, disk, and network diagnostics where they can explain a bottleneck.

For latency, report relevant percentiles, normally p50, p95, and p99, with population, time window, units, and sample count. Show errors and timed-out or unfinished work alongside successful latency; a timeout is not an observed completion time. Use extreme percentiles only with enough observations to make them informative. Compute aggregate percentiles from compatible samples or merged histograms, rather than averaging window percentiles.

For sustained workloads, retain throughput and latency time series so stalls, drift, and maintenance remain visible. Separate run-to-run variation from within-run variation. Define every error bar or interval and its unit of observation. Account for dependence in time-series samples; adjacent samples are not independent trials.

Check each result against hardware limits: bytes per second against memory, disk, and network bandwidth, and operations per second times CPU cost per operation against available cores. A result past a limit measured something other than the useful work, such as a cache hit, a no-op, or a failed request.

Report absolute values and effect size against the named baseline. State the ratio's direction: throughput speedup is candidate/baseline; elapsed-time speedup is baseline/candidate. Include dispersion or uncertainty. Label effects unresolved when the evidence cannot distinguish them from noise.

**Complete when:** summaries can be recomputed from retained measurements and readers can distinguish useful performance, failed work, instability, and uncertainty.

## 6. Explain and hand off

Lead with the answer to the original decision, scoped to the measured workload and environment. Name each candidate's limiter, the resource that bounds it, with diagnostic evidence from runs separate from the reported ones. A result without a named limiter is an observation, not an explanation. Separate observations from causal hypotheses; test a causal hypothesis by changing a relevant factor when scope allows it. Compare results with the step 1 prediction and explain large gaps.

Bound application impact with Amdahl's law: report a microbenchmark gain together with the measured share of end-to-end time spent in the benchmarked code.

Leave this record in the repository's normal benchmark location or requested deliverable:

1. Experiment specification, environment manifest, workload inputs or generator/seeds, and effective configuration.
2. Exact setup, execution, and analysis commands, with reproducible versions and dependencies.
3. Run identifiers, ordering, warmup/reset details, raw measurements, outcome counts, exclusions, and summary generation.
4. Results with units, absolute values, effect sizes, variability, scope, limitations, and unresolved questions.

For an implementation-only task, provide the runnable harness and commands and identify measurements still needed. For a review, prioritize findings that could change the conclusion and cite their code location or supplied evidence. Identify proposed runs, smoke-test output, and measured performance explicitly.

**Complete when:** another engineer can rerun the experiment and regenerate its summaries, or the deliverable identifies the evidence still unavailable. Every performance claim must trace to an actual measurement.
