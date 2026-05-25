# Release and Upgrade Documentation

This document defines how changes between versions are documented so that both **humans** and **AI agents** can understand them and act on them. It covers two distinct document types with two distinct audiences:

| Type | File | Primary audience | Answers the question |
|------|------|------------------|----------------------|
| **Application release notes** | `docs/releases/vX.Y.md` | Admins, users, operators of the deployed app | "What changed, and what must I do to run the new version?" |
| **Library upgrade guide** | `docs/releases/upgrade-to-X.Y.md` | Consumers of the library — developers **and AI agents** in a downstream project | "How do I move my project from the old version to this one, completely and without collateral damage?" |

A repository produces one or the other depending on what it ships: a deployable application produces release notes; a published library or shared dependency produces upgrade guides. A repository that ships both (e.g. an app that also publishes a reusable module) produces both.

## Core Principles

1. **One file per version.** Each released version gets its own document. Never rewrite the history of a previous release — published release/upgrade docs are an immutable record. New versions add new files.
2. **Derive from reality, not memory.** The content of a version-delta document must come from the actual git history, diffs, tags, merged PRs, and the code itself — never from recollection of "what probably changed." A wrong upgrade guide is worse than none.
3. **Match the document to its reader.** Release notes are written for people operating software and must be readable without the source. Library upgrade guides are written to be *executed* — primarily by an AI agent — and must be concrete enough to act on.
4. **GitHub Flavored Markdown**, imperative/present tense, no trailing whitespace.

---

## Application Release Notes

Location: `docs/releases/vX.Y.md` (use the full version, e.g. `v1.4.md`, matching the GitHub release tag).

Audience: people who run or administer the application. They care about visible changes, operational impact, and what they must do to upgrade a deployment. They generally do **not** read the source.

### Required Structure

```markdown
# <App> vX.Y – Release Notes

**Released:** YYYY-MM-DD
**GitHub release:** [vX.Y](<url to the release tag>)
**Previous version:** [vX.(Y-1)](<url>) (YYYY-MM-DD)

<One short intro paragraph naming the theme of the release and flagging
any single significant change up front.>

---

## Highlights for Admins and Users

### <Feature or change>

<What changed, in user-facing language, and — crucially — WHY it matters
to the reader. Group by change. Cover new capabilities, removals,
improvements, and notable fixes.>

---

## Other changes under the hood

<Technical changes not directly visible to end users but useful to know:
dependency updates, internal refactors, expanded test coverage, new
developer docs.>

---

## Upgrade notes

<The operational checklist for moving a deployment to this version:>
- Database migrations required? If none, say so explicitly.
- Any destructive change (removed feature/table) that needs a data export
  BEFORE upgrading? Call out data-loss risk loudly.
- Configuration / environment / integration compatibility.

---

## Full commit history

The complete technical list of changes is available in the Git history
between the tags:

`git log vX.(Y-1)..vX.Y --oneline`
```

### Rules

- Every highlighted change explains its **impact on the reader**, not just the fact that it happened.
- **Removals and destructive changes are flagged explicitly**, with the action the operator must take before upgrading (e.g. export data).
- When nothing is required for an upgrade step, **say so explicitly** ("No database migrations are required") — silence is ambiguous.
- Keep it user-centered; technical detail belongs under "Other changes under the hood" or in the library upgrade guide.

---

## Library Upgrade Guides

Location: `docs/releases/upgrade-to-X.Y.md` (one file per target version, e.g. `upgrade-to-0.16.md`). Release notes and upgrade guides share the `docs/releases/` directory.

Audience: a developer or, more importantly, **an AI agent** working in a *downstream project* that depends on this library. The document is not a passive description — **it is a prompt to be executed.**

### The defining requirement

> Given only this file and access to a consumer project's codebase, a competent AI agent must be able to perform the upgrade **correctly, completely, and without touching anything out of scope.**

If a human has to open the library's source to understand what to do, the guide has failed. Everything the agent needs — exact signatures, column definitions, message strings, config keys, ordering — lives in the file.

### Required Structure

```markdown
# Upgrade prompt: `<group:artifact or npm package>` A.B.x → C.D.0

## Prompt

<One or two sentences stating, in plain terms, what this upgrade does to a
consumer: the mandatory changes and the optional ones.>

### What changed in C.D.0

#### Dependencies

<Which coordinate(s) to bump, to exactly which version. Then state
explicitly what must NOT change — peer frameworks, transitive deps,
unrelated versions. Scope discipline starts here.>

#### Breaking: <name of the change>

<Exact before/after. Real signatures, annotations, column definitions,
validation message strings, config keys — copy-pasteable, not described.>

#### Breaking-light: <name of the change>

<Subtle breakage that compiles but behaves differently or breaks tests —
e.g. a changed error-message string that breaks string-equality assertions.>

#### Additive: <name of the change>

<New optional capability. State clearly that adoption is OPTIONAL and that
NOT adopting it leaves existing behavior unchanged.>

##### <Runtime / conditional requirement, if any>

<Conditions under which extra setup or a new optional dependency is needed.>

### Steps

1. <Ordered, verifiable steps the agent runs top to bottom: bump the
   coordinate, run migrations in the correct order, edit call sites, fix
   tests, verify the build.>

### Guard rails

- Do **not** <constraint that prevents a correct-looking but wrong action>.

### Don't do this

- <Named anti-pattern or tempting shortcut the agent must avoid, e.g.
  shimming the old API with an overload, or bumping unrelated deps.>
```

### Rules

- **Classify every change by severity** using a tag in the heading:
  - **Breaking** — the consumer's code will not compile or run until it is changed.
  - **Breaking-light** — it still compiles, but behavior or test assertions change (message strings, defaults, side effects).
  - **Additive** — a new optional capability; defaults preserve old behavior; not adopting it is safe.
- **Mandatory vs. optional must be unambiguous.** For every optional change, state that skipping it is safe and what the resulting (unchanged) behavior is.
- **Be concrete and self-contained.** Include real before/after signatures, schema definitions, and string literals. No "see the source" or "adjust as needed."
- **Order matters in migrations.** Where steps have ordering constraints (e.g. backfill data before applying a `NOT NULL` constraint), state the order and why, and add a matching guard rail.
- **Call out test-breaking changes** — changed messages, enum values, or defaults that downstream assertions depend on.
- **Enforce scope.** The guide drives *only* the changes this version requires. Guard rails forbid bumping unrelated dependencies or bundling other refactors into the upgrade.
- **One target version per file.** Upgrading across several versions means running the relevant files in sequence; never collapse multiple version jumps into one document.

### Self-check before publishing a library upgrade guide

Confirm all of the following. If any fails, the guide is incomplete:

- [ ] The exact coordinate and target version to bump are stated, and what must not change is listed.
- [ ] Every breaking change has concrete before/after the agent can match against a consumer codebase.
- [ ] Optional changes are clearly marked optional, with the safe default behavior stated.
- [ ] Migration steps are ordered, and ordering-sensitive steps have guard rails.
- [ ] Guard rails and "Don't do this" close off the predictable wrong moves.
- [ ] An agent with only this file and a consumer repo could finish the upgrade and verify it.

---

## Canonical examples

These live documents are the gold standard for each type. The `release-doc` skill also bundles trimmed copies in its `examples/` folder for offline use.

- **Application release notes** — [open-crm `docs/releases/v1.4.md`](https://github.com/OpenElementsLabs/open-crm/blob/main/docs/releases/v1.4.md)
- **Library upgrade guide (breaking)** — [spring-services `docs/upgrade-to-0.16.md`](https://github.com/OpenElementsLabs/spring-services/blob/main/docs/upgrade-to-0.16.md)
- **Library upgrade guide (additive)** — [open-elements-ui `docs/upgrade-to-0.6.md`](https://github.com/OpenElementsLabs/open-elements-ui/blob/main/docs/upgrade-to-0.6.md)

> Note: the existing library repos currently keep these files directly under `docs/`. This convention standardizes their location to `docs/releases/`; align repos to that path when next touched.
