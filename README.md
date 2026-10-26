# Skills

My agent skills. They follow the [Agent Skills](https://agentskills.io) format, so they work in Claude Code, Codex, Copilot, Gemini CLI, Cursor, OpenCode and anything else that reads `SKILL.md`.

## Install

**Claude Code**

```bash
claude plugin marketplace add JasonLovesDoggo/skills
claude plugin install jason-skills@jasonlovesdoggo
```

**Codex**

```bash
codex plugin marketplace add JasonLovesDoggo/skills
codex plugin add jason-skills@jasonlovesdoggo
```

**Any other agent, or editable copies**

```bash
npx skills@latest add JasonLovesDoggo/skills
```

## Skills

### Model-invoked

- **[benchmarking](./skills/benchmarking/SKILL.md)**: Design, run, and audit performance benchmarks and AI evals. Starts from the claim you expect to ship, guards against overfitting with holdouts and a frozen harness, audits every win for gaming, and reports a verdict from at least 5 alternating runs per side.
- **[performance](./skills/performance/SKILL.md)**: Make code faster. Makes a napkin math estimate, names the limiter, and works through a hot-path checklist covering passes, early exits, data layout, allocations, I/O calls, batching versus streaming, concurrency, awaits, and threads.

### User-invoked

- **[hindsight](./skills/hindsight/SKILL.md)**: Redesign what you just built with hindsight. Finds the early decision that forced most of the code, checks the redesign's assumptions against real code, and sizes the simpler version line by line. Run it after the first end-to-end run, or before opening the PR.

## License

MIT
