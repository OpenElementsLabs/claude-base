---
name: release-doc
license: Apache-2.0
metadata:
  source: https://github.com/open-elements/claude-base
  author: Open Elements
description: Create version-change documentation that helps humans and AI understand and act on changes between versions. Produces application release notes (docs/releases/vX.Y.md) for operators, or — for libraries — an AI-executable upgrade guide (docs/releases/upgrade-to-X.Y.md) that lets an agent upgrade the dependency in a downstream project. Use this skill when the user wants to write release notes, a changelog for a version, an upgrade or migration guide, or document what changed between two versions.
argument-hint: [target version to document, e.g. v1.4 or 0.16.0]
---

# Create Release / Upgrade Documentation

Produce the documentation that explains what changed between two versions and what a reader must do about it. There are two output shapes for two audiences:

- **Application release notes** (`docs/releases/vX.Y.md`) — for the humans who operate the deployed app.
- **Library upgrade guide** (`docs/releases/upgrade-to-X.Y.md`) — an AI-executable prompt that lets an agent upgrade this dependency inside a *downstream* project.

Before starting, read `../../../conventions/release-documentation.md` for the full structure, naming, and rules of both document types. This skill operationalizes that convention; the convention is the source of truth for format.

Worked, gold-standard examples live in `examples/` next to this skill — read the one matching your document type and mirror its structure (see `examples/README.md` for the index and links to the live canonical docs).

## Core rule

The content of these documents must come from the **actual git history and the code**, never from memory. A release note that misses a breaking change, or an upgrade guide that describes the wrong signature, is worse than no document. Verify every claim against the diff.

## Instructions

### 1. Determine the document type

Decide whether this repository ships an **application** or a **library** (or both):

- **Application** — a deployable product (web app, service, container). → Release notes for operators.
- **Library** — a published artifact consumed by other projects (Maven/Gradle coordinate, npm package, shared module). → Upgrade guide for consumers.

Detect this from the project: look at the build file (is it published with coordinates / a package name, or deployed as an app?), the README, and the existing `docs/` directory. If it is genuinely ambiguous, or the repo ships both, ask the user which document to produce.

### 2. Establish the version delta

Pin down exactly which two points you are documenting:

- **Target version** — the version being released/published (from the user, the build file, or the planned tag).
- **Previous version** — the last documented version. Find it from existing tags (`git tag --sort=-v:refname`), the previous file in `docs/releases/`, or ask.

Then gather the real changes between them — do not rely on memory:

- `git log <previous>..<target> --oneline` for the change set.
- Inspect merged PRs / commit messages for intent and grouping.
- For anything that looks structural, read the actual diff. In particular, for libraries, diff the **public API surface** and contracts:
  - `git diff <previous>..<target> -- <public source paths>` for changed/removed/added public signatures.
  - Database schema / migration files for schema changes.
  - Configuration keys, default values, validation messages, enums, and exported types.

Summarize the delta back to the user grouped into: **breaking changes**, **new/optional capabilities**, **fixes/internal changes**. Confirm nothing significant is missing before writing.

### 3a. Application release notes

Create `docs/releases/vX.Y.md` following the structure in the convention doc; use `examples/application-release-notes.md` as the model. Focus on the reader who operates the app:

- Frame each highlighted change in user-facing terms and explain **why it matters**, not just that it happened.
- Flag every removal or destructive change loudly, with the action required **before** upgrading (e.g. export data first).
- In **Upgrade notes**, be explicit even about the absence of work ("No database migrations are required"). Cover migrations, data-loss risks, and config/integration compatibility.
- Keep deep technical detail under "Other changes under the hood."

### 3b. Library upgrade guide

Create `docs/releases/upgrade-to-X.Y.md` following the structure in the convention doc. This is the high-stakes path — the document must be **executable by an AI agent against a downstream project**. Use `examples/library-upgrade-breaking.md` as the model when there are breaking changes, or `examples/library-upgrade-additive.md` for a purely additive release.

Work the changes systematically:

1. **Walk the full public contract delta** from step 2 — every changed/removed public method, type, annotation, schema column, config key, default, and message string. Each one is a potential consumer break.
2. **Classify each change** with a severity tag in its heading: **Breaking** (won't compile/run), **Breaking-light** (compiles but behavior/tests change), or **Additive** (optional; old behavior preserved).
3. **Write concrete before/after** for each — real signatures, column definitions, and literals the agent can match against a consumer's code. No "see the source," no "adjust as needed."
4. **Write ordered Steps** the agent runs top to bottom, including which coordinate to bump and to what version, migrations in the correct order (e.g. backfill before `NOT NULL`), call-site edits, test fixes, and a verification step.
5. **Write Guard rails and "Don't do this"** — explicitly forbid the predictable wrong moves: bumping unrelated/peer dependencies, leaving constraints off, passing `null` for new required args, shimming the old API to avoid the migration, bundling unrelated refactors.
6. State clearly, for every **optional** change, that skipping it is safe and what the unchanged behavior is.

Before finishing, run the self-check from the convention doc. The bar is: *with only this file and a consumer repo, could an agent complete and verify the upgrade?* If not, fill the gap.

### 4. Place and link the document

- Put the file in `docs/releases/` with the exact naming from the convention (`vX.Y.md` for release notes, `upgrade-to-X.Y.md` for library upgrade guides).
- If a previous version's document exists, do **not** edit it — these are an immutable record. Only add the new file.
- If the project keeps an index/listing of releases or upgrade guides, add the new entry.

### 5. Summary

Provide:
- A link to the created document and the version delta it covers.
- For libraries: the list of breaking changes captured and confirmation that the self-check passes (or which items remain open).
- For applications: a reminder to attach the notes to the GitHub release for the matching tag.
