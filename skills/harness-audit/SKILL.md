---
name: harness-audit
description: Use this skill when the user asks to evaluate, review, audit, sanity-check, or optimize their current agentic setup — system prompt, active skills, available tools, and recent conversation. Surfaces contradictions, dead references, scope creep in skills, missing guardrails, and concrete optimization opportunities.
---

# Harness Audit

You are auditing the agentic harness you are currently running inside. Treat this as a structured review, not a free-form chat. Your job is to produce findings the user can act on.

You do not know which harness this is (Claude Code, OpenCode, Pi, a custom runner, something else). Do not guess or assume. Inspect what is actually exposed to you at runtime and reason from that.

## 1. Scope the audit first

Before doing anything else, ask the user **one** focused question:

> Is there a specific area you want me to focus on (e.g. a particular skill, tool, recurring failure, prompt section), or should I do a general sweep?

Rules:
- Ask once. Do not interrogate.
- If they name specific areas, treat those as priorities, **not blinders**. Still flag serious issues you encounter elsewhere — just keep them brief and clearly separated from the requested scope.
- If they want a general sweep, cover all the categories in section 4 with roughly equal depth.

## 2. Gather the actual state

Use what is genuinely available in this runtime. Do not invent capabilities.

Inspect, in this order:

1. **System prompt / base instructions** — what the agent is told it is, what it must/must not do, defaults, persona, language, safety rules.
2. **Active skills** — names, descriptions, trigger conditions, instructions, declared tool usage.
3. **Available tools** — names, parameters, declared side effects, scopes, allowed paths, read/write capability.
4. **Conversation history so far** — patterns of tool use, retries, errors, ignored instructions, contradictions the agent already walked into.
5. **Environment signals** — current working directory, OS, allowed paths, available shells, network access, user preferences, timezone, etc. — only what is actually observable.

If something you need is not observable, say so explicitly. Do not fabricate.

## 3. Probe with non-destructive calls

Active probing is encouraged where it adds signal. Keep probes **read-only and side-effect-free**.

Good probes:
- Listing a directory you think a skill expects to exist.
- Reading a file referenced by a skill or prompt.
- Calling a tool with a trivial/no-op input to confirm it is wired up.
- Checking a tool's parameter schema against how a skill instructs you to call it.

Forbidden during audit:
- Writes, deletes, moves, renames.
- Network calls with side effects (posting, sending, paying, triggering webhooks).
- Anything that changes user state, repo state, or remote systems.
- Running shell commands beyond inspection (`ls`, `cat`, `pwd`, `--help`, `--version`).

If a check would require a destructive action, **describe the check and ask the user** instead of executing it.

## 4. What to look for

Use these categories as a checklist. For each finding, capture: evidence, why it matters, and the fix.

### Tool ↔ skill mismatches
- Skill instructs use of a tool that is not exposed in this harness.
- Skill calls a tool with parameters that do not match the tool's schema.
- Skill assumes a tool capability the tool does not actually have (e.g. recursion, globs, auth).
- Tool exists but is unreachable due to permissions, allowed paths, or sandboxing.

### Read/write and permission contradictions
- Skill tells the agent to write/modify/delete in a location that is read-only or outside allowed paths.
- Skill assumes network access in an offline harness, or vice versa.
- Skill assumes persistence (memory, files) that this harness does not provide between sessions.

### Skill design problems
- One skill doing several unrelated jobs — candidate for splitting.
- Overlapping or duplicate skills with unclear precedence.
- Vague or generic `description` that will not reliably trigger (or will over-trigger).
- Trigger conditions that contradict the skill's own body.
- Skill instructions that conflict with the system prompt or with another skill.
- Hardcoded harness assumptions (paths, tool names, model names) that break portability.

### System prompt issues
- Internal contradictions.
- Rules the available tools cannot enforce or satisfy.
- Defaults that fight the user's stated preferences.
- Missing guardrails around destructive actions, secrets, or untrusted input.
- Persona/style rules that override or muddy task correctness.

### History / behavior signals
- Repeated tool failures the agent did not learn from.
- The agent ignoring or contradicting its own instructions.
- Loops, retries, or fallbacks that mask a structural problem.
- Skills that should have triggered but did not, or triggered when they should not have.

### Safety and blast radius
- Destructive operations without confirmation, dry-run, or rollback.
- Secret handling that leaks via logs, tool args, or echoed output.
- Untrusted content (files, web pages, tickets) being treated as instructions.

## 5. Output format

Deliver findings in this shape. Keep it scannable.

**Summary** — 3–6 lines: overall health, top 1–3 issues, top 1–2 quick wins.

**Findings** — a table or list, each entry containing:
- **Title** — short, specific.
- **Severity** — `critical` / `high` / `medium` / `low` / `nit`.
- **Where** — system prompt section, skill name, tool name, or history reference.
- **Evidence** — quoted snippet or observed behavior. No paraphrasing of critical claims.
- **Why it matters** — concrete failure mode, not abstract.
- **Recommendation** — exact change, split, removal, or rewrite. Prefer diffs or rewritten text over prose.

**Open questions** — anything you could not verify without destructive action or user input.

**Suggested next actions** — ordered, smallest-effort-first.

## 6. Ground rules

- Be radically honest. If a skill is bad, say so and explain why.
- Separate facts (observed), inferences (reasoned), and guesses (uncertain). Label them.
- Do not pad. If there are only three findings, deliver three findings.
- Do not recommend rewrites you have not thought through — give the user something they can paste.
- Stay harness-agnostic. Refer to "this harness" / "the current runtime", never to a specific product unless the runtime itself confirms it.
- If you find nothing meaningful in a category, say "no issues found" and move on. Do not invent problems.
