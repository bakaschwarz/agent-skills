# agent-skills

[![skills.sh](https://skills.sh/b/bakaschwarz/agent-skills)](https://skills.sh/bakaschwarz/agent-skills)

A growing collection of **portable, agent-agnostic skills** for AI coding assistants.

These skills are plain Markdown. They do not depend on any specific agent runtime. You can use them with **Claude Code, Cursor, Codex CLI, Aider, Continue, Cline, Windsurf**, or anything else that can read instructions from a file.

> Inspired by [mattpocock/skills](https://github.com/mattpocock/skills), but written to be tool-neutral and reusable across agents and stacks.

## Why skills?

Coding agents are powerful, but they fail in predictable ways:

* **Misalignment** — the agent builds the wrong thing because it never asked the right questions.
* **Verbosity** — walls of text where a diff, checklist, or short decision record would do.
* **Broken code** — confident output without a real feedback loop, tests, or verification.
* **Big ball of mud** — features pile on without enough architectural pressure.

A **skill** is a small, focused Markdown document that teaches an agent how to handle one situation well.

Good skills are:

* **Portable** — usable across different agents and editors.
* **Composable** — small enough to combine with other skills.
* **Version-controlled** — easy to review, update, and share.
* **Operational** — written as concrete instructions, not vague advice.

## Quickstart (30-second setup)

Install all skills at once using the [skills.sh](https://skills.sh) installer:

```bash
npx skills@latest add bakaschwarz/agent-skills
```

Pick the skills you want and which coding agents to install them on. That's it.

### Install individual skills

```bash
npx skills@latest add bakaschwarz/agent-skills/handoff
npx skills@latest add bakaschwarz/agent-skills/harness-audit
npx skills@latest add bakaschwarz/agent-skills/readme-update
npx skills@latest add bakaschwarz/agent-skills/simple-issues
```

### Manual setup

If you prefer not to use the installer, clone the repo and load skills directly:

```bash
git clone https://github.com/bakaschwarz/agent-skills.git
```

Then point your agent at the relevant `SKILL.md` files — see [Using a skill](#using-a-skill) below.

## Using a skill

Most skills can be invoked in one of two ways:

* **Explicitly** — by name or slash command, e.g. "use the `handoff` skill".
* **Implicitly** — by loading it as standing instructions so the behaviour kicks in whenever the trigger condition matches.

Each skill documents its own trigger, expected behaviour, and output format.

### Loading skills in your agent

#### Claude Code

The installer handles this automatically. To load manually:

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)/skills"/* ~/.claude/skills/
```

#### Cursor or Windsurf

Symlink or copy individual `SKILL.md` files into your project rules directory, for example `.cursor/rules/` or `.windsurf/rules/`.

#### Codex CLI, Aider, Continue, Cline, or similar agents

Reference the relevant skill file from your project's standing instructions, such as `AGENTS.md` or `CONVENTIONS.md`:

```markdown
When reviewing code, follow the instructions in:
./skills/code-review/SKILL.md
```

#### Any other agent

Paste the contents of the relevant `SKILL.md` into the agent's context.

## Available skills

| Skill | Purpose |
|---|---|
| [`handoff`](./skills/handoff/SKILL.md) | Creates a structured `context/handoff.md` at the end of a session so the next agent can pick up without prior context. Validates the output with a lint script. |
| [`harness-audit`](./skills/harness-audit/SKILL.md) | Audits the current agentic setup — system prompt, active skills, available tools, and conversation history. Surfaces contradictions, dead references, missing guardrails, and concrete improvements. |
| [`readme-update`](./skills/readme-update/SKILL.md) | Keeps `README.md` in sync with the codebase by cross-referencing git history with the current README content. Handles creation from scratch if no README exists. |
| [`simple-issues`](./skills/simple-issues/SKILL.md) | Manages a zero-infrastructure, file-based issue tracker under `.issues/` with `open/`, `claimed/`, and `closed/` folders. No external tooling required — works entirely via the filesystem and git. |

## Repository layout

```text
agent-skills/
├── README.md
├── LICENSE
└── skills/
    ├── <skill-name>/
    │   ├── SKILL.md          # the actual instructions
    │   └── examples/         # optional: reference inputs and outputs
    └── ...
```

## Authoring a new skill

1. Create a new kebab-cased folder under `skills/`, for example `skills/my-skill/`.
2. Add a `SKILL.md` file with frontmatter (`name`, `description`, optional `triggers`).
3. Keep the scope tight: **one skill, one job**. If it's growing, split it.
4. Write instructions in the imperative mood, addressing the agent directly ("Ask the user…", "Refuse to…", "Output only…").
5. Avoid tool-specific assumptions. Prefer "read the file" over "use the Read tool".
6. Add examples under `examples/` if the expected behaviour is non-obvious.
7. Link the skill in the table above.

### Style guidelines

* **Short over clever.** If a skill needs hundreds of lines, it is probably multiple skills.
* **Concrete over abstract.** Include expected output formats, checklists, or examples.
* **State failure modes.** Tell the agent what not to do.
* **Prefer reversible steps.** Especially for infrastructure, production, secrets, and data-loss risks.
* **No hype.** Skills are operational instructions, not marketing copy.

## Contributing

Pull requests are welcome. Open an issue first if you are proposing a larger skill, a naming convention change, or a structural change.

## License

MIT
