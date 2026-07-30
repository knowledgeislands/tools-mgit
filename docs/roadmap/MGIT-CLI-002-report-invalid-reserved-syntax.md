---
id: MGIT-CLI-002
title: Report invalid reserved syntax before help
theme: cli
horizon: future
status: open
candidate: true
blocks: []
blocked-by: []
baseline-ref: null
transferred-from: knowledgeislands/tools-ki:KI-TOOL-CLI-013
---

## Context

Make invalid syntax for mGit's reserved commands and options fail explicitly even when a help flag is present. The command must preserve its deliberate generic Git-command pass-through: an unrecognised positional command is not necessarily a mGit error, but malformed `register`, `repair`, `structure`, `worktree`, or `completion` syntax and unknown global options must not appear to succeed by printing help.

## Boundary

Do not reject arbitrary Git subcommands or options that mGit deliberately fans out to Git. Do not add compatibility aliases for removed mGit commands, infer corrections for ambiguous input, or alter valid help and command dispatch.

## Discussion

### Diagnostic contract

For mGit-owned grammar, an unrecognised option or unexpected argument remains a non-zero usage error even when a following or preceding help flag is present. The diagnostic should identify the invalid input and affected command before showing that command's help. A suggestion is appropriate only for an unambiguous, durable correction.

### Relationship to KI

`KI-TOOL-CLI-013` supplies the reproduced CLI-parser concern. mGit has a materially different command model because normal positional input is Git command input, so its local item applies the principle only at the boundary of reserved mGit syntax.
