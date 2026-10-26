---
name: benchmarking
description: Design, run, and audit performance benchmarks and AI evals. Use when writing a benchmark or eval harness, comparing implementations, configurations, services, models, prompts, or agents, reporting a measured speedup, regression, or eval score, or checking someone else's numbers.
---

# Benchmarking

These steps apply to runtime benchmarks and AI evals. Before step 2, read the reference for your measurement:

- **Runtime** (speed, throughput, latency, memory): [references/runtime.md](references/runtime.md)
- **AI evals** (models, prompts, agents): [references/evals.md](references/evals.md)
- **Services and databases**, in addition to runtime: [references/services-and-databases.md](references/services-and-databases.md)

Agents tuning against a benchmark game it, even when told not to. Audit every win with step 5 before you report it.

## Choose the path

- **Ballpark:** the user asked for a quick number. Run once, count outcomes and work done (step 4), and say it was one run. A choice between options is never a ballpark.
- **Design:** specify steps 1–6 without running them.
- **Run:** do steps 1–7.
- **Audit:** someone else's number, or one from an agent loop. Do step 5 first, since it finds most problems in minutes. Treat an LLM's audit of a claim as a lead, and confirm each finding in the code or raw data.

## 1. Write the claim

Before running anything, write the sentence you expect to ship: metric, direction, size, workload, and baseline. For example, "export is 30% faster at p50 than v2.3 on the 60k-row dataset", or "model B passes 12 more of 300 held-out tasks than model A at the same token budget." Under it, write:

- the decision the result informs;
- the smallest difference that would change that decision;
- your prediction of each candidate's result. For runtime, use napkin math from the `performance` skill.

## 2. Choose the workload

- **Cases:** cover typical inputs, large inputs, and contention. Label synthetic stress cases with what they exercise. Include inputs that can trigger algorithmic blowups; a case that never finishes counts as a failure.
- **Holdout:** if anyone tuned a candidate against the benchmark, including an agent, the claim rests on a holdout set that:
  - shares no cases with the tuning set;
  - differs in input shape, because overfit code wins on inputs shaped like the tuning set and loses on the rest;
  - is chosen by someone who knows the domain and did not do the tuning;
  - runs in full, not as an arbitrary subset.

  Tell the tuner, human or agent, that it will be judged on a holdout it cannot see. In Dan Luu's [regex experiment](https://danluu.com/benchpocalypse/), this generalized better than telling the agent not to overfit. Freeze the candidate before showing holdout results. If those results guide more tuning, the holdout is used up, so build a new one.
- **Weights:** fix how cases combine before running. Weight a summary by real usage, and give separate scores for workloads that answer different questions, such as compile-heavy versus long-running. An unweighted geometric mean treats every case as equally important. Down-weight or drop cases that do not reflect real use, and say which.

**Done when:** the case list, the holdout and who chose it, and the weights are written.

## 3. Control the comparison

- **Same work:** every candidate does the same useful work under the same guarantees: correctness, precision, durability, consistency, and failure handling. A candidate that changes the semantics, such as searching whole files where the benchmark specifies line by line, does different work.
- **Settings:** when comparing implementations, run each with the settings production would use. If one is held back by a setting, such as a debug build, a missing index, or one commit per row, fix it and rerun. When the settings themselves are being compared, such as defaults, keep them and name them in the claim.
- **Environment:** record the commit of every candidate and of the harness, plus what the reference lists for your measurement. Each number describes one commit.
- **Noise:** stop competing work. When you cannot, interleave candidates so both see the same noise, and say so.

**Done when:** each difference between candidates is controlled, deliberately varied, or disclosed.

## 4. Build and freeze the harness

Use the repository's benchmark framework when one exists.

- **Outcomes:** count attempted, succeeded, failed, timed out, retried, and unfinished work. A timeout is a failure.
- **Work done:** check outputs against an oracle or invariant on every run, and print a count of work completed.
- **Smoke test:** run once and check counts, units, and outputs. Label that output as a smoke test.
- **Freeze:** commit the harness, inputs, grader, and invocation, and run every comparison from that commit. The interface (how candidates are called and what they may precompute) is part of the harness. A harness change by whoever tuned a candidate voids the comparison until someone else reviews it. Treat an agent-written harness as unreviewed until it is checked against the benchmark's documented method.

## 5. Audit for gaming

Run these checks on every win before you report it:

- **Harness:** diff it against the frozen commit and against the benchmark's documented method.
- **Candidate:** read its diff for code keyed to the benchmark: special-cased inputs, sizes, or answers; results returned without reading the input; precomputation the interface does not allow.
- **Perturbation:** change seeds, values, sizes, and order, then recheck correctness and the gain. If the gain depends on some input property, limit the claim to workloads with that property.
- **Holdout:** compare tuning-set and holdout results. Find out whether the gap comes from overfitting or from a harder workload, and report where the gain holds.
- **Real use:** check the result on real workloads, because benchmark rankings and real-use rankings diverge.
- **Transcripts:** for evals, read passes as well as failures.

**Done when:** every check passed or led to a fix, and the post-fix results replaced the earlier ones.

## 6. Run

- Fix the run count before measuring: at least 5 per candidate, alternating A, B, A, B. Record the order.
- Report the median and range, and compare the difference with step 1's minimum. Overlapping ranges mean no measurable difference, which does not prove the candidates equal. When the call is close, apply a rank-sum test (Mann–Whitney U) to the per-run results.
- Keep exploratory runs out of the final comparison. Keep failed and excluded runs, each with its reason.

## 7. Report

Lead with the verdict: better, worse, no measurable difference, or inconclusive. Follow with the claim sentence as measured, including unit, run count, median, and range. For example, "p50 41 ms → 33 ms, median of 7 runs per side, range 32–35 ms after, bound by JSON parsing on one core."

The verdict is inconclusive, and the report names the gap, when:

- a candidate was held back by a setting (step 3);
- outcomes or work done were not counted;
- a tuned candidate has no holdout result;
- the harness changed mid-comparison, or step 5 was skipped;
- for runtime, the limiter is unnamed.

Include the per-case table and the weights behind any summary. Keep the commands, commits, environment, raw measurements, run order, exclusions, and summary scripts so someone else can regenerate every number. Label each figure as proposed, smoke test, or measured. A PR body gets one primary number and a link to the rest.
