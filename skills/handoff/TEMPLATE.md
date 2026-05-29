# Handoff: <short task title>

<!--
This document is the single source of truth for the next agent or human picking
up this task. Other files under context/ (e.g. plan.md, research.md) are
session-local and may have been wiped by the time you read this. Anything that
matters from those files must be inlined here, not referenced.
-->

## Meta

| Key            | Value                                  |
|----------------|----------------------------------------|
| Date           | YYYY-MM-DD                             |
| Branch         | `<branch-name>`                        |
| HEAD           | `<short-sha>`                          |
| Session start  | `<short-sha or ISO timestamp>`         |
| Status         | in-progress \| blocked \| review \| done |
| Author agent   | `<agent name/model, e.g. claude-opus-4-7>` |

## TL;DR

One short paragraph (3–6 sentences) covering: what the task is, where it stands right now, and what the next agent should do first. If the next agent reads only this section, they should not make a wrong move.

## Task Summary

What was the task? Include the original goal, scope, and any explicit non-goals. Link to issues, tickets, or specs by path/URL if applicable.

## Context & Background

Why this work is happening, relevant prior decisions, constraints (deadlines, compatibility, performance budgets, security requirements), and assumptions made during the session. Call out anything the next agent could easily get wrong without this context.

Inline anything important that lived in ephemeral `context/*` files (plans, research notes, intermediate findings). Do not reference those files — they may not exist anymore.

## Status

Concrete current state. Use a checklist if there are sub-goals.

- [x] Sub-goal A — done, verified by `<how>`
- [ ] Sub-goal B — in progress, blocked on `<what>`
- [ ] Sub-goal C — not started

## Edited Files

Grouped by status. Use repo-root-relative paths. Add a one-line note per file explaining what changed and why.

Do **not** list ephemeral session artifacts under `context/` (e.g. `context/plan.md`, `context/research.md`). Only `context/handoff*.md` is allowed here.

### Added
- `path/to/new_file.ext` — purpose / what it does

### Modified
- `path/to/changed_file.ext` — what changed and why

### Deleted
- `path/to/removed_file.ext` — reason

### Renamed / Moved
- `old/path` → `new/path` — reason

### Possible work artifacts (please confirm)
- `path/maybe_scratch.md` — unclear if real work or helper file

If a subsection has no entries, write `_None._` on the line below it.

## Commits

Newest first. Format: `<short-sha> <subject>`. If there are none, write `_None._`.

- `abc1234` feat(parser): extract parseConfig into config/parse.ts
- `def5678` test(parser): add unit tests for parseConfig

## Decisions & Rationale

Non-obvious decisions made during the session, with the reasoning and the alternatives that were considered and rejected. Future-you will thank present-you.

- **Decision:** chose X over Y.
  **Why:** …
  **Trade-off:** …

## Test & Verification Status

What was actually run, what passed, what failed, what was not tested. Include exact commands.

- `pnpm test` — all green (142 passed)
- `pnpm lint` — not run
- Manual check: `<describe>`

## Open Points

Things still to do or decide that are part of this task.

- [ ] …
- [ ] …

## Problems & Caveats

Known issues, footguns, surprises, flaky behavior, environmental quirks, hacks left in place. Be honest. The next agent needs to know where the sharp edges are.

- ⚠️ …
- ⚠️ …

## Environment & Setup Notes

Anything non-default needed to reproduce the working state: env vars, local services, ports, feature flags, fixtures, secrets locations (names only, never values), required tool versions.

## Skills to Load

Skills the next agent should load to continue this task and its likely follow-ups. One sentence per skill explaining why.

- `skill-name` — why it is relevant here

## Next Steps

Ordered, concrete actions. The first item should be runnable immediately.

1. …
2. …
3. …

## References

Issues, PRs, docs, design notes, related handoffs, external links. Only `context/handoff*.md` is acceptable as a `context/` reference here.

- …
