---
name: open-elements-project-setup-and-review
description: This skill has a full understand of the structure we use at Open Elements for projects. This includes libraries, backends, frontends or full applications. The skill can review if a project fits to the specification and can give feedback on how to improve the project structure. The skill can also help to set up a new project based on the specifications and best practices of Open Elements, update a project based on them or even create a new project.
---

# Open Elements Project Setup and Review

This skill is designed to help with the setup and review of projects at Open Elements.
A project in that case is most ofen a GitHub repository that contains code for a library, backend, frontend or full application.
It provides guidance on project structure, best practices, and helps ensure that projects align with our standards and guidelines.
Whether you're setting up a new project or reviewing an existing one, this skill can provide valuable insights and recommendations.

## Project types

A project can be a Java library, a TypeScript library, a Java Backend (Spring Boot or Helidon SE based), a Web Frontend or a full application (containing 1-N back-ends and 1-N front-ends).
Depending on the project type, the skill will provide specific guidance on how to set up the project structure, what files and folders to include, and how to organize the code.

## Instructions

Before performing any review or setup task, **read all convention documents first** to have full knowledge of Open Elements standards. The docs are located relative to this skill at `../../conventions/`:

1. Read all of the following files:
   - `../../conventions/software-quality.md` — API design, technical integrity, namespace, SBOM, CI
   - `../../conventions/repo-setup.md` — required root files (README, LICENSE, CoC, .gitignore)
   - `../../conventions/documentation.md` — Markdown, MkDocs, GitHub Pages, ADRs
   - `../../conventions/java.md` — Java conventions
   - `../../conventions/typescript.md` — TypeScript conventions
   - `../../conventions/backend.md` — Backend frameworks, REST/OpenAPI, database, observability
   - `../../conventions/fullstack-architecture.md` — Frontend/backend separation, Docker, configuration, pinned tool versions
   - `../../conventions/project-specific/README.md` — Project-specific docs (if any exist)

2. Determine the project type (Java library, TypeScript library, Java backend, web frontend, or fullstack application).

3. Based on the project type, apply only the relevant conventions:
   - **All projects**: `software-quality.md`, `repo-setup.md`, `documentation.md`
   - **Java projects**: additionally `java.md`
   - **TypeScript projects**: additionally `typescript.md`
   - **Backend projects**: additionally `backend.md`, `java.md`
   - **Frontend projects**: additionally `typescript.md`
   - **Fullstack projects**: additionally `fullstack-architecture.md`, `backend.md`, `java.md`, `typescript.md`

4. When **reviewing** an existing project: compare the project structure, files, and conventions against the applicable docs. List what matches, what is missing, and what should be changed.

5. When **setting up or updating** a project: apply all applicable conventions and create/modify files accordingly.

## Project Types

A project can be a Java library, a TypeScript library, a Java Backend (Spring Boot or Helidon SE based), a Web Frontend or a full application (containing 1-N back-ends and 1-N front-ends).
Depending on the project type, the skill will provide specific guidance on how to set up the project structure, what files and folders to include, and how to organize the code.
