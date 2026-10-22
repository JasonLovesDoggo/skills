Each skill lives at `skills/<name>/SKILL.md`, one level deep, so every installer finds it.

When you add, rename, or remove a skill, update all three: its entry in `README.md` (name linked to its `SKILL.md`), its path in `.claude-plugin/plugin.json`'s `skills` array, and the symlinks via `scripts/link-skills.sh`. Then run `claude plugin validate . --strict`.

A user-invoked skill needs both flags: `disable-model-invocation: true` in `SKILL.md` for Claude Code, and `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for Codex.

Bump `version` in `.claude-plugin/plugin.json` on every release; plugin installs only update when it changes.

Write skills generically: no company, repo, or ticket names in a skill's body or examples.
