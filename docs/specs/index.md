# mgit specifications

This corpus records the current, testable behavior of mgit. It complements decisions that explain why behavior exists, guides that explain how to use it, and roadmap items that schedule changes.

## Reading a requirement

Each numbered requirement states one current behavior using normative language and ends with a concrete verification hook. Requirements are append-only: an obsolete one is retained and marked deprecated rather than renumbered.

## Identifier scheme

`MGIT-WS-NNN` identifies a workspace-dispatch requirement. Serials are zero-padded, sequential within their prefix, and never reused.

## Gaps

Each area may end with an unnumbered `## Gaps` section. A gap is a potential or missing behavior, not part of the as-built contract, and gains an identifier only after it is implemented.

## Areas

| File                  | Prefix    | Covers                                                      |
| --------------------- | --------- | ----------------------------------------------------------- |
| workspace-dispatch.md | `MGIT-WS` | Repository discovery, selection, groups, and command fan-out |
