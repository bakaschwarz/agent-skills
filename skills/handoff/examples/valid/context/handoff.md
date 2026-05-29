# Handoff: Sample valid document for lint self-test

## Meta

| Key            | Value                          |
|----------------|--------------------------------|
| Date           | 2026-05-29                     |
| Branch         | `feature/parser-refactor`      |
| HEAD           | `abc1234`                      |
| Session start  | `def5678`                      |
| Status         | in-progress                    |
| Author agent   | `claude-opus-4-7`              |

## TL;DR

Extracted parser logic from `cli.ts` into a dedicated module. Tests pass locally. Next agent should wire the new module into the CLI entrypoint and re-run the full test suite. No blockers.

## Task Summary

Refactor the parser out of `cli.ts` to make it independently testable, without changing observable behavior.

## Context & Background

The CLI has grown to ~600 LOC and unit tests had to spawn the CLI process. Extracting the parser unblocks proper unit testing and a planned switch to a streaming parser later.

## Status

- [x] Extract `parseConfig` into `src/config/parse.ts`
- [x] Add unit tests for happy path
- [ ] Wire new module back into `cli.ts`
- [ ] Add error-path tests

## Edited Files

### Added
- `src/config/parse.ts` — extracted parser module
- `tests/config/parse.test.ts` — unit tests

### Modified
- `src/cli.ts` — removed inline parser (wiring still missing)

### Deleted
_None._

### Renamed / Moved
_None._

## Commits

- `abc1234` refactor(parser): extract parseConfig into config/parse.ts
- `def5678` test(parser): add unit tests for parseConfig

## Decisions & Rationale

- **Decision:** kept the public function name `parseConfig`.
  **Why:** avoids touching call sites in this pass.
  **Trade-off:** name is slightly generic for the new module location.

## Test & Verification Status

- `pnpm test` — 142 passed, 0 failed
- `pnpm lint` — not run

## Open Points

- [ ] Wire `parseConfig` from `src/config/parse.ts` back into `cli.ts`
- [ ] Add error-path tests for malformed config

## Problems & Caveats

- ⚠️ `cli.ts` currently does not compile; the inline parser is gone but the import is not added yet.

## Environment & Setup Notes

- Node 20.x
- `pnpm install` required after pulling
- No env vars needed for tests

## Skills to Load

- `typescript-refactor` — for the wiring step
- `test-runner` — to validate after wiring

## Next Steps

1. Add `import { parseConfig } from "./config/parse";` to `src/cli.ts` and replace the removed call site.
2. Run `pnpm typecheck && pnpm test`.
3. Add error-path tests in `tests/config/parse.test.ts`.

## References

- Issue: `PROJ-481`
- Related handoff: `context/handoff-2026-05-28.md`
