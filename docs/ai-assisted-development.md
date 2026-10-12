# AI-assisted development notes

This repository was built in a single session with Claude Code, using two add-ons: the **graphify** skill (code-to-knowledge-graph) and the **Ponytail** plugin (a "smallest complete change" coding style). This page records what worked, what did not, and what to do differently, so contributors and AI agents do not repeat the same mistakes.

Short version: Ponytail helped the code; graphify did not help a project this size and turned into a loop. Agent rules derived from this are in [`CLAUDE.md`](../CLAUDE.md).

## graphify

[graphify](https://github.com/Graphify-Labs/graphify) turns a folder into a knowledge graph (`graph.json`, `graph.html`, `GRAPH_REPORT.md`) using an AST pass for code and an LLM pass for documents. Version used: 0.9.63.

### What happened

- The graph was built once and then refreshed with `/graphify --update` after almost every code change (6 runs, about 323k input tokens in total).
- Every run re-extracted `README.md` with an LLM subagent (about 60-70k tokens each), needed the same manual edge fixes, and suggested nearly the same questions.
- The questions it kept raising ("the target chips are isolated nodes", "the project node is the main bridge") came from how the README is written, not from real problems in the code. Answering them changed nothing.
- On the first run, graphify itself warned: *"Corpus is ~1,565 words - fits in a single context window. You may not need a graph."* That warning was right and should have ended the experiment.
- The output folder (`graphify-out/`) was eventually removed from the repository and is now in `.gitignore`.

### Problems found in graphify (candidate [upstream issues](https://github.com/Graphify-Labs/graphify/issues))

1. **PowerShell dot-sourcing and script-scope calls produce no edges.** The AST pass creates no `imports` edge for dot-sourcing (`. "$PSScriptRoot\other.ps1"`) and drops calls made at script scope, outside any function. Calls made inside a function body do resolve across files. In this repo, `build.ps1`, `flash.ps1` and `hexconfig.ps1` load `toolchain.ps1`, and `flash.ps1` loads `hexconfig.ps1` and calls `Format-HexConfig` at script scope, so the edges had to be added by hand on every update. Reported upstream with a minimal repro: [Graphify-Labs/graphify#4356](https://github.com/Graphify-Labs/graphify/issues/4356). Root cause: the dot-source handler reads the path only when tree-sitter parses it as `command_name` (quoted paths are `string_literal`, unquoted `$PSScriptRoot\...` is `path_command_name`), and calls are collected only from function bodies. Fix with regression tests proposed in [Graphify-Labs/graphify#4369](https://github.com/Graphify-Labs/graphify/pull/4369); `. (Join-Path ...)` stays unresolved because the path is only known at runtime.
2. **Stale edges survive incremental merges.** An INFERRED edge from the first run (`examples/blink/main.c` -> `CONFIG bits`, no `source_location`) survived two later `--update` runs. Both endpoints still existed (the code file was unchanged and the README concept was recreated with the same ID), so the merge kept the old edge even though no new extraction produced it. Not reported upstream (no minimal repro yet); closest existing issues: Graphify-Labs/graphify#1152, Graphify-Labs/graphify#2406.
3. **Gemini backend fails silently on a missing dependency.** With `GOOGLE_API_KEY` set, the skill routes document extraction to Gemini, but the installed package lacked the `openai` dependency that backend needs. The chunk failed with a warning and produced no nodes; extraction had to fall back to a subagent. Related: Graphify-Labs/graphify#3616 (failed chunks reported as model omissions).
4. **Whole-document re-extraction cost.** Any edit to the README re-extracts the full file. For a frequently edited README, each small change costs a full LLM pass.
5. **The workflow nudges toward loops.** The skill's instructions end every run by offering "the most interesting question" to trace. On a small corpus this produces the same questions every time.

Workarounds used while it was still in use: pass the existing node IDs to the extraction subagent so README concepts keep stable IDs across runs, and check for edges without `source_location` after each merge.

### When graphify makes sense

Large or unfamiliar codebases, mixed corpora (code plus papers, docs, images), or questions that cross many files. Not a repository of about a dozen files you can read in a few minutes. If its report says the corpus fits in one context window, believe it.

## Ponytail

Ponytail is a Claude Code plugin that sets a "lazy senior developer" style: the smallest change that fully solves the task, no speculative abstractions, a small test for any new non-trivial logic, `shortcut:` comments for known limits, and a closing line on what was skipped or risky.

### Where it helped

- **Small, focused diffs.** No new dependencies and no abstractions nobody asked for. Every script stays a single readable file.
- **Tests for new logic.** The Intel HEX / CONFIG reader got `tests/hexconfig.test.ps1`. That test caught a real bug when PIC24/dsPIC/PIC32 support was added: the device files give the register width sometimes as decimal (`32`) and sometimes as hex (`0x20`), and the first version read only decimal.
- **Known limits written in the code.** While `hexconfig.ps1` supported only 8-bit parts, a `shortcut:` comment said so and when to extend it. It was removed when the other families were added.
- **Explicit risks.** Most answers ended with what was not verified, most importantly that no chip has actually been programmed yet (see [Status](../README.md#status)).

### Where it was not applied

- Its first question is "does this need to exist?". That question was never asked about the graphify graph. The graphify skill's instructions (always update, always offer the next question) won over that question, and the result was the loop described above.
- A few small unrequested changes slipped in (for example deleting a stale `.hex` before each build). They are defensible, but would have been better proposed first.

## Lessons

- When two tool instructions pull in opposite directions (exhaustive exploration versus minimal change), decide explicitly instead of following whichever ran last.
- Treat a tool's own "you may not need this" warning as a stop sign.
- Hardware-facing scripts need a human in the loop: build and CONFIG reading were tested automatically, but programming a real chip is still untested and should be reported when someone does it.
