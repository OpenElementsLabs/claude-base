# Workflow Skills

This folder contains the **workflow skills** of the Open Elements Claude base configuration. Unlike the language/convention skills (which silently shape *how* code is written), workflow skills drive **multi-step processes** a developer runs deliberately: planning a feature, implementing it through a proper GitHub flow, reviewing it, documenting a release, or auditing a whole project.

You trigger a workflow by typing its slash command (e.g. `/spec-create`) or by describing the task in natural language — Claude matches your request to the right skill. This guide covers the big picture, what each workflow does, which files they create, how to use them, and what to set up first.

## Table of contents

1. [The big picture](#the-big-picture) — general ideas and how the workflows fit together
2. [Workflows at a glance](#workflows-at-a-glance) — a short description of each
3. [Generated files and folders](#generated-files-and-folders) — what ends up in your repo
4. [Usage examples](#usage-examples)
5. [Dependencies and setup](#dependencies-and-setup) — `gh`, tokens, build tools

---

## The big picture

The workflows are built around **spec-driven development**: non-trivial work is *planned as a specification before it is implemented*, and the plan, the decisions, and the divergences are all kept as durable Markdown files under `docs/` — so the reasoning behind the code survives, and both humans and Claude can pick up where the last session left off.

The full arc, from a vague idea to a merged Pull Request, looks like this:

```
        ┌─────────────┐
idea →  │  /vision    │  product discovery → docs/vision.md
        └──────┬──────┘
               │  pick a feature
               ▼
        ┌─────────────┐     ┌──────────────┐
        │ /spec-create│ ──► │  /adr-create │  (for architecturally
        └──────┬──────┘     └──────────────┘   significant decisions)
               │  design.md + behaviors.md
               ▼
        ┌──────────────┐
        │/spec-implement│  → steps.md (ordered task plan)
        └──────┬───────┘
               ▼
        ┌─────────────────────────────────────────────┐
        │                /spec-flow                    │  end-to-end orchestration:
        │  issue → branch → implement → review → PR     │  ties the steps below together
        └──────┬───────────────────┬───────────────────┘
               ▼                   ▼
        ┌─────────────┐     ┌──────────────┐
        │/spec-review │     │/quality-review│  completeness vs. spec  +  code quality
        └─────────────┘     └──────────────┘
```

Two cross-cutting ideas show up again and again:

- **Stress-testing before committing.** `/grill-me` is a relentless Socratic interview used as a building block: `/vision`, `/spec-create`, and `/adr-create` all run it first, so assumptions are challenged *before* they get written down.
- **A clean GitHub flow.** Planning produces issues; implementation happens on a feature branch; review gates the merge; the result is a Pull Request ready for a human. `/spec-flow` automates this whole loop, and `/roadmap-execute` runs it autonomously for every step of a roadmap.

Not every idea is ready to become a spec. `/todo-capture` is the lightweight counterpart to `/spec-create`: when a half-formed idea, a deferred sub-task, or a follow-up surfaces — during planning, grilling, reviewing, or general work — it is parked as an entry in `docs/TODO.md` instead of being lost. When a parked item matures, it graduates back into the arc above via `/spec-create` or a GitHub issue.

Around this core sit the **quality and documentation** workflows: `/project-analyze` keeps the project's context current, `/project-quality-audit` and `/reproducible-builds-check` audit health and build integrity, and `/release-doc` produces version documentation.

---

## Workflows at a glance

### Discovery & planning

| Workflow | What it does | Main output |
|----------|--------------|-------------|
| **`/vision`** | Interactive product discovery — user stories, personas, scope, prioritized features. Stress-tested with `/grill-me`. | `docs/vision.md` |
| **`/spec-create`** | Plans one feature or bug fix as a spec through discussion (starting from a GitHub issue or a description). | `docs/specs/<id>/design.md` + `behaviors.md` |
| **`/adr-create`** | Records one architecturally significant decision with justification and rejected alternatives. Grills the decision first. | `docs/adr/NNNN-*.md` |
| **`/grill-me`** | Relentless Socratic interview that walks every branch of a decision tree to surface hidden assumptions. Used by the three above, and standalone. | — (clarity; feeds other docs) |
| **`/todo-capture`** | Quickly parks a half-formed idea, deferred sub-task, or follow-up as a backlog entry — without interrupting the work in progress. The lightweight counterpart to `/spec-create`. | `docs/TODO.md` entry |

### Implementation & review

| Workflow | What it does | Main output |
|----------|--------------|-------------|
| **`/spec-implement`** | Turns a completed spec into an ordered, step-by-step task plan. | `docs/specs/<id>/steps.md` |
| **`/spec-flow`** | End-to-end: creates the GitHub issue (if missing), branches, runs spec-implement, iterates spec-review + quality-review until clean, opens a PR. | feature branch + Pull Request |
| **`/spec-review`** | Checks whether the implementation fully covers the spec's design and behaviors; records divergence in a Drift Log. | review report + Drift Log entries |
| **`/quality-review`** | Reviews a code change/diff against the project's conventions (quality, security, language rules, testing). | review report |
| **`/roadmap-execute`** | Autonomously processes every unchecked step in `docs/roadmap.md`, delegating each to a fresh sub-agent (spec → implement → review → commit). | commits + updated roadmap |

### Quality, context & build integrity

| Workflow | What it does | Main output |
|----------|--------------|-------------|
| **`/project-analyze`** | Scans the project and (re)generates the **Project Context** section of `CLAUDE.md` (features, tech stack, structure, architecture). | updated `CLAUDE.md` |
| **`/project-quality-audit`** | Read-only whole-project release-readiness audit: README, license, buildability, dependency resolvability, docs, coverage, secrets/hygiene. | report (optionally `docs/quality-audit.md`) |
| **`/reproducible-builds-check`** | Enforces/audits/sets up reproducible builds (version pinning, deterministic output) for Maven/Node/Docker. | report + build-config changes |

### Documentation

| Workflow | What it does | Main output |
|----------|--------------|-------------|
| **`/release-doc`** | Application release notes for operators, or AI-executable upgrade guides for libraries. | `docs/releases/vX.Y.md` or `docs/releases/upgrade-to-X.Y.md` |

---

## Generated files and folders

The workflows converge on a uniform `docs/` layout plus the project's `CLAUDE.md`. After using them, a project typically looks like this:

```
project-root/
├── CLAUDE.md                         ← /project-analyze maintains its "Project Context" section
└── docs/
    ├── vision.md                     ← /vision
    ├── roadmap.md                    ← hand-written; consumed by /roadmap-execute
    ├── TODO.md                       ← lightweight backlog of parked ideas (/todo-capture)
    ├── quality-audit.md              ← /project-quality-audit (only if you ask to save it)
    ├── specs/
    │   ├── INDEX.md                  ← central index of all specs (id, status, area, issue)
    │   └── 001-user-auth-flow/       ← one folder per spec, prefixed with a sequential id
    │       ├── design.md             ← technical design (/spec-create); frozen once "done"
    │       ├── behaviors.md          ← given-when-then scenarios (/spec-create)
    │       └── steps.md              ← optional ordered task plan (/spec-implement)
    ├── adr/
    │   ├── README.md                 ← index of decision records
    │   └── 0001-use-postgres.md      ← one ADR per decision (/adr-create)
    └── releases/
        ├── v1.2.md                   ← application release notes (/release-doc)
        └── upgrade-to-2.0.md         ← library upgrade guide (/release-doc)
```

A few conventions worth knowing:

- **Specs are numbered and indexed.** Each spec is a folder `NNN-kebab-title/` and must have an entry in `docs/specs/INDEX.md`. The index is the at-a-glance overview of what exists and what is implemented.
- **`design.md` / `behaviors.md` freeze when a spec is `done`.** They are a historical record. Later changes that make the code diverge are not edited in place — `/spec-review` appends them to a **Drift Log** at the bottom of the affected file, so the original intent and the later reality are both visible.
- **All spec documents are written in English**, regardless of the conversation language, so they stay accessible to every contributor.
- **`docs/TODO.md` is a living backlog**, not an archive. `/todo-capture` adds entries; once an item graduates into a spec or issue it is removed (or struck through with a pointer), so the file only ever lists what is still open.
- The full structure and file formats are defined in [`_workflow-shared/spec-driven-development.md`](_workflow-shared/spec-driven-development.md), which the spec workflows load on demand.

---

## Usage examples

**Plan and implement a new feature, end to end:**

```
/spec-create
> "Add API-key authentication so external systems can call our REST API."
# → produces docs/specs/004-api-key-auth/design.md + behaviors.md

/spec-flow
> "Implement spec 004."
# → creates the issue, branches, implements, reviews until clean, opens a PR
```

**Start from scratch with a product idea:**

```
/vision
> "I want to build a CRM for small open-source foundations."
# → docs/vision.md with personas, scope, and a prioritized feature list
# then run /spec-create for each "Must Have" feature
```

**Park an idea that is not ready for a spec yet:**

```
/todo-capture
> "While building the import, we noticed duplicate companies get created.
>  Note a follow-up to add a merge feature later."
# → appends an entry to docs/TODO.md with context and prerequisites,
#   without derailing the current task
```

**Record an architecture decision:**

```
/adr-create
> "Should we use PostgreSQL or MongoDB for the event store?"
# → grills the decision, then writes docs/adr/0007-event-store-database.md
```

**Audit a project before making it public:**

```
/project-quality-audit
> "Is the open-crm repo ready to be public?"
# → runs the real build + tests, checks README/license/docs/coverage/secrets,
#   and reports a PASS / PASS WITH WARNINGS / FAIL verdict
```

**Refresh the project context after big changes:**

```
/project-analyze
# → re-scans the codebase and updates the Project Context section of CLAUDE.md
```

**Run a whole roadmap autonomously:**

```
# write docs/roadmap.md with a checklist of milestones, then:
/roadmap-execute
# → works through each unchecked step with a fresh sub-agent and commits as it goes
```

---

## Dependencies and setup

Most workflows need nothing beyond the repository itself. The ones that interact with GitHub or run real builds have extra requirements.

### GitHub access (`/spec-create`, `/spec-flow`)

These workflows read issues, create issues and Pull Requests, and watch CI checks. Two things provide GitHub access, and they read **different** environment variables — set both to the same Personal Access Token to be safe:

1. **The GitHub MCP server** (configured in `.mcp.json`) reads `GITHUB_PERSONAL_ACCESS_TOKEN`.
2. **The `gh` CLI** (used directly for `gh issue view`, `gh pr create`, `gh pr checks`) reads `GH_TOKEN` (or uses an interactive `gh auth login`).

Put the token(s) in **`.claude/settings.local.json`** (this file is gitignored — never commit a real token):

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here",
    "GH_TOKEN": "ghp_your_token_here"
  }
}
```

Variables under `env` are exported into the Claude Code session, so both the MCP server and the `gh` CLI pick them up. The token needs `repo` scope (read/write issues and pull requests) for the project you are working on.

You also need the **`gh` CLI** installed (`gh --version`) and **`git`** configured with push access to the repository (`/spec-flow` creates and pushes a feature branch).

### Build toolchains (`/project-quality-audit`, `/reproducible-builds-check`)

These workflows execute the project's real build and tests, so the project's toolchain must be available:

- **Java/Maven** — a JDK matching `.sdkmanrc` and the Maven Wrapper (`./mvnw`).
- **TypeScript/Node** — Node matching `.nvmrc` and the pinned package manager (e.g. `pnpm` via `corepack enable`).
- **Docker** — required when tests use Testcontainers, or when auditing Docker build reproducibility.

If a required toolchain or a pinned version is missing, the audit reports it as a finding rather than guessing.

### Sub-agents (`/roadmap-execute`)

`/roadmap-execute` spawns a fresh sub-agent per roadmap step (via the `Agent` tool), so it must run in an environment where sub-agents are available (Claude Code or Cowork).

### Internal dependencies between workflows

Some workflows invoke others automatically — no setup needed, just be aware:

- `/vision`, `/spec-create`, and `/adr-create` invoke **`/grill-me`** to stress-test before writing.
- `/spec-flow` invokes **`/spec-implement`**, **`/spec-review`**, and **`/quality-review`**.
- `/roadmap-execute` drives **`/spec-create`**, **`/spec-implement`**, and **`/spec-review`** inside its sub-agents.
