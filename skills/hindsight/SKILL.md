---
name: hindsight
description: Redesign what was just built with hindsight, and size the simpler version. Run after the first end-to-end run, or before opening the PR.
disable-model-invocation: true
---

You built this, so you now know things nobody knew at the start. Use that **hindsight** to find the design you would build if you started over today, and how much smaller it would be. "Keep the current design" is a valid result when the redesign saves little.

## Steps

1. **List what the build taught you.** Go through the session and the diff for every fact learned along the way: test and benchmark results, review comments, runs through the real path, each course change. Write one line per fact saying which starting assumption it confirmed or broke. Done when every course change and every surprise has its line.

2. **Find the load-bearing choice.** For each large part of the diff, ask why it is that size and trace it back to the early decision that forced it. Pick the one or two decisions that, made the other way, delete the most code. Done when each fits one sentence of the form "<decision>, so <consequence>: <files it forced>".

3. **Find what was built by hand.** For each hand-built part, name the library feature or existing code in the repo that already does it. Done when every hand-built part has a named replacement or a reason it is custom.

4. **Check the hinge.** The redesign rests on claims about code that already exists. Read that code now and confirm each claim. Done when every claim is confirmed or broken by a file and line, or listed as open with the exact read or command that settles it.

5. **Design it again.** Describe the from-scratch version: its modules, what each owns, and which layers of today's build it drops under the deletion test. Measure today's size with `git diff --stat` against the base, per PR when it is a stack. Done when a table shows current lines against estimated lines for each PR or module.

6. **Name the decisions to settle up front.** List the course changes that were cheap to decide before building and expensive to undo after. These become the questions for the next design note.

7. **Report.** Lead with the load-bearing choice and the size difference. Then the redesign table, the hinge checks, the up-front decisions, and process incidents last, briefly. End with one next step: the smallest spike that proves the redesign, or keeping the current design.
