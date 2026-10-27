---
id: KI-TOOL-MGIT-CLI-031
area: CLI
title: Learn command shapes
kind: deliver
purpose: capability
component: cli
priority: medium
size: m
horizon: future
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-22T10:36:39Z
updated_at: 2026-10-22T10:37:32Z
---

> **Idea, not on the roadmap.** Let a learned command recognise later invocations with the same structure even when argument values change; six design questions are still open. Moved out of `docs/roadmap/` on 27 October 2026 under the roadmap sweep, with its record kept in full here so that it can return when Kris brings it back; it was `KI-TOOL-MGIT-CLI-031`.

# Learn command shapes

## Goal

Let a learned command recognise later invocations with the same declared structure even when argument values change. Users can see which flags make a match and which optional flags do not affect it.

## Context

Kris requested this draft on 22 October 2026, in these words:

> on the `mgit learn`, how do we deal with params that might change... e.g. `mgit ci -am "<msg>"` so learn needs to think about the command structure, i.e. 1. expand the alias, which is just `ci` -> `commit` in this case (note that `st` is `status -sb`) 2. state which params are considered in the match, e.g. -a is optional/ignored, -m is the key one to make this a match, but its value, i.e. `"<msg>"` is ignored

### Current command identity

[The executable](<../../bin/mgit#L3631>) resolves the leading Git alias before deriving the template filename. `resolve_git_aliases` asks `git config --get alias.<name>` in the invoking process's Git context, prepends the expansion's words to the remaining arguments, and repeats up to ten times. It splits each expansion with Bash `read -r -a`, rather than a Git-compatible quoted-word parser; empty and `!` shell expansions stop resolution. This is existing alias handling, not a built-in alias catalogue: `ci` and `st` only have the quoted meanings when the effective Git configuration defines them.

Alias definitions come from Git configuration visible to that lookup: applicable system, global/XDG, repository-local and enabled worktree configuration, their includes, and command/environment configuration available to Git. They do not come from shell aliases or the `.mgit.toml` manifest. The lookup has no per-selected-checkout `-C`; actual dispatch runs the original arguments through Git inside each selected checkout, where repository-specific aliases can differ. Resolving that mismatch is an open design decision.

`template_file` keys on the complete expanded argument vector, preserving flags, their order and their values. It joins words with `_` and percent-encodes characters outside `[A-Za-z0-9.,=@+-]`; an underscore within a word is encoded. Thus `st` and explicit `status -sb` share `status_-sb.template` when that alias is configured, but `commit -am "first"` and `commit -am "second"` use different files, as do `-am` and separate `-a -m`. There is no command-shape declaration or combined-short-flag normalisation in this identity path. [Dispatch lookup](<../../bin/mgit#L4631>) and [forget](<../../bin/mgit#L3850>) use that same filename calculation.

### Current learned output and display

[Learning and listing](<../../bin/mgit#L3776>) store one plain-text file under `${XDG_CONFIG_HOME:-$HOME/.config}/mgit/templates/`, containing comments, a shell-escaped `command:` line and `stdout:`/`stderr:` lines. `command:` is descriptive metadata; lookup uses the filename, and `template_read` reads only output lines. `learn --list` prints each stored command and its file; `learn --forget` removes the expanded literal command's file. There is no shape metadata or migration path today.

Learning really executes the command. After successful execution across all selected checkouts, mgit normalises checkout details in stdout and stderr to `{path}`, `{remote-url}`, `{upstream}`, `{remote}`, `{branch}` and `{repository}`, longest values first, leaving values shorter than two characters alone. A non-empty output shared by a strict majority requires terminal confirmation before it is saved; all-empty output already counts as quiet. Later successful commands are quiet only when both normalised streams match exactly, with trailing newlines removed by the current reader/capture. A shape match would select an output template; it would not by itself establish that a checkout is quiet.

The [user guide](<../guides/user/running-commands.md#learn-normal-output>), [README](<../../README.md>) and [manual](<../../man/mgit.1#L658>) describe this alias-expanded, exact-output behaviour. Existing [Bats fixtures](<../../tests/mgit.bats#L784>) configure `st = status -sb` in an isolated global Git configuration and prove that learning `st` also quiets explicit `status -sb`. Further [tests](<../../tests/mgit.bats#L895>) cover output placeholders, majority confirmation, empty/failing output, listing/forgetting and filenames encoding literal arguments. They do not establish value-independent command shapes.

## Boundary

This record captures future product work only. It does not approve implementation, change code, templates, user configuration, documentation of accepted behaviour, command execution, repository selection or release state. Retain standalone Bash 3.2 and Git as the only runtime dependencies. Any eventual mutating verification must use disposable repositories and isolated configuration.

## Discussion

### Proposed matching model

First expand ordinary Git aliases, preserving flags supplied by their definitions: `ci` becomes `commit`, while `st` becomes `status -sb`. Then parse the resulting arguments against a declared per-command shape. Normalisation affects matching only; send the user's original invocation to Git as today unless a separately reviewed decision changes execution.

Each command declaration needs to name its significant flags, its optional/ignored flags, and the arity of recognised options so their values can be consumed without mistaking them for commands or flags. Flag values are excluded from shape identity. A significant flag's presence is part of the match; an optional/ignored flag's presence or absence does not change it. Do not infer interchangeable flags just because two runs happen to print the same output.

For the requested `commit` example, declare `-m` significant with one ignored value and `-a` optional/ignored with no value. Parse `-am "first"` into `-a`, `-m`, and the message argument; it matches `-a -m "second"` and `-m "third"`, whereas a command without `-m` does not match that shape. Splitting must follow option arity, stopping at a value-taking short flag rather than splitting characters of an attached value. For the `st` example, carry `-sb` through alias expansion and interpret it as `-s -b` under the `status` declaration; which status flags are significant remains to be declared.

Long-option equivalents, option ordering, repeated flags, attached values, positional arguments and `--` need explicit rules before readiness. Unknown or unsupported forms must not silently acquire a broader match. Recognition of an alias never authorises execution of a `!` shell alias during shape construction.

### Storage and user presentation

A learned entry should retain the normalised stdout/stderr template together with an inspectable canonical shape: the expanded command, significant flags, ignored optional flags, and value-ignoring rules. An illustrative display is `commit: requires -m <ignored>; optional/ignored -a`. This is a proposal, not an agreed persistence schema or CLI syntax.

Choose a stable shape identity independent of message values and alias spelling, with one deterministic lookup path for learn, ordinary dispatch and forget. Explain the shape and any replacement/collision at confirmation; `learn --list` should show the shape, its effective match rules and storage location. Forgetting should identify the shape being removed. Decide where command declarations live and how an entry remains understandable when those declarations or aliases change.

### Existing entries and migration

Preserve existing files and their literal identity until an explicit migration policy is agreed. Prefer retaining legacy exact matching as a fallback and offering a reviewed conversion that previews old commands, proposed shapes and collisions before writing. Never silently merge several literal entries into one broader shape, choose between different output templates, or discard an entry whose command cannot be reconstructed safely. Conversion should be repeatable, preserve a recovery copy and avoid evaluating stored command text. Existing files can contain literal values in filenames, `command:` and comments; ignoring values in new matching does not remove that historical content.

### Verification considerations

A future plan needs fixtures for alias chains and aliases with flags, caller/checkout configuration differences, bundled and separate short options, changed message values, absent significant flags, optional flags, attached and long values, repeated options, `--`, unsupported forms, shape display/forget and legacy conversion conflicts. Keep existing confirmation, failure visibility, exact normalised output comparison and repository-selection guarantees covered.

The commit example also exposes a separate limitation: successful commit output includes details such as a commit identifier and message that existing checkout placeholders do not remove. Ignoring a message in the lookup key alone does not make that output reusable. Resolve expected output treatment explicitly; this record does not assume arbitrary output values can safely be ignored.

### Open questions

1. **Alias authority and parsing:** Keep caller-context Git configuration, resolve per checkout, or require a common expansion across the selected set? How should quoted aliases, chains/cycles, depth exhaustion, `!` aliases and Git options before the command behave?
2. **Declaration ownership and coverage:** Ship a bounded command catalogue, allow user-authored declarations, or both? Which flags beyond `commit -m` and optional `-a` are significant, especially `--amend`, and which `status` flags distinguish shapes? What happens for undeclared commands or flags?
3. **Canonicalisation rules:** How do long equivalents, attached values (`-mtext`, `--message=text`), repeated options, flag ordering, positional arguments and `--` affect identity? All flag values are ignored for matching, but their arity and unsupported syntax still need deterministic treatment.
4. **Persistence and display:** What exact shape/declaration representation and storage key should be used, and are rules embedded or referenced? How should learn confirmation, list, forget, collisions and later declaration changes expose the effective match? Should original argument values be retained as provenance or omitted from new files?
5. **Migration policy:** Is conversion explicit or automatic with a preview? What precedence applies when legacy literal and shape entries both match, and how are conflicting outputs, unsafe-to-parse commands, backups and rollback handled?
6. **Output variability:** Is the first delivery limited to shape-based lookup with existing exact output comparison, or must it also make the commit example's changing output reusable? If the latter, what narrowly declared output normalisation is safe?

### Sizing and readiness

Provisional `size: m`: one repository, a reviewed design and several coherent implementation/documentation/verification commits covering parsing, persistence and migration. Classification is `deliver` / `capability`, component `cli`, with medium priority. The owner requested a draft; Future retains the unresolved design without scheduling implementation. Reassess size or split before promotion if general Git parsing or output normalisation substantially expands it. No missing build prerequisite is known; the open questions are shaping decisions, not fabricated dependency records. Promotion requires their resolution and an agreed verification plan.
