# AI evals

The unit of observation is the task.

## Workload (step 2)

- **Task count:** one pass rate over n tasks has a standard error of about √(p(1−p)/n). At p = 0.5 and n = 200, that is ±7 points at 95%. Use pilot runs to size the task set so that the paired difference you care about is clearly larger than its interval.
- **Contamination:** keep holdout tasks out of tuning, and keep reference answers out of anything the candidate can see. Prefer fresh private tasks, and disclose any unknown overlap with training data. Verbatim recall can reveal contamination, but its absence does not rule contamination out.
- **Coverage:** draw tasks from the real distribution, weight categories by real use, and report a score per category.

## Comparison (step 3)

- **Controls:** vary only the component being compared, whether that is the model, prompt, scaffold, or tools. For whole-agent comparisons, record each complete setup and match the declared budget for tokens, time, and attempts. Before each attempt, restore the starting workspace, conversation, memory, and tool state.
- **Environment:** record every model ID with its version or date, the provider, and the sampling settings.
- **Cost:** report tokens, dollars, latency, and attempts per task next to each score. State whether the decision uses score alone or cost per solved task.
- **Infrastructure failures:** count rate limits, API errors, and sandbox crashes apart from task failures. Apply one declared rerun policy to every candidate.
- **Order:** interleave candidates in time, so provider-side changes and load affect all of them.

## Grader (step 4)

- **Validate the grader:** compare it with human judgment on a sample of passes and failures, and report its false-pass and false-fail rates.
- **LLM judges:** hide which candidate produced each answer, randomize answer order, pin the judge model and prompt version, and calibrate against human labels.
- **Test-based grading:** keep hidden scoring tests and reference answers out of the candidate's reach, and run grading outside its writable environment. Development tests that belong to the task stay visible.

## Runs and statistics (step 6)

- **Samples:** when outputs vary, run each task at least 5 times. Report pass@1 as the mean over samples, and define any pass@k you report.
- **Paired comparison:** compare candidates on the same tasks. With one pass/fail result per candidate per task, use McNemar's test. With repeated or graded results, average within each task, then bootstrap over tasks for an interval on the score difference, resampling related tasks together. Five attempts on 200 tasks are 200 observations, not 1,000. Compare the interval with zero and with step 1's minimum.

## Audit (step 5)

- **Transcripts:** read a sample of passes as well as failures. Look for these signs of reward hacking:
  - edited, deleted, or skipped tests;
  - code special-cased to the test inputs;
  - answers read from files or context;
  - answers that get credit for matching the format while failing the task;
  - success claimed without the work being done.
- **Real use:** run the candidates on real tasks from the target workflow. Leaderboard order and real-use order often disagree, and a model that scores lower on public benchmarks can do better in practice.
