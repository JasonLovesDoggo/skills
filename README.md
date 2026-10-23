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

- **[benchmarking](./skills/benchmarking/SKILL.md)**: Design, implement, run, and review software performance benchmarks with controlled comparisons and reproducible evidence.

### User-invoked

- **[hindsight](./skills/hindsight/SKILL.md)**: Redesign what you just built with hindsight. Finds the early decision that forced most of the code, checks the redesign's assumptions against real code, and sizes the simpler version line by line. Run it after the first end-to-end run, or before opening the PR.

## License

MIT
