# Fullstack Architecture Conventions for Claude Code

## Overview

In Open Elements projects that have both a frontend and a backend,
both parts are treated as fully independent applications within a single repository.
They share no code, no build process, and no runtime.
The only coupling is at the network level through APIs.

A reference implementation of this architecture is [maven-initializer](https://github.com/support-and-care/maven-initializer).

## Repository Structure

```
project-root/
├── backend/              # Independent backend application
│   ├── Dockerfile        # Standalone container build
│   ├── src/              # Backend source code
│   └── ...               # Backend build files (pom.xml, build.gradle, etc.)
├── frontend/             # Independent frontend application
│   ├── Dockerfile        # Standalone container build
│   ├── src/              # Frontend source code
│   └── ...               # Frontend build files (package.json, etc.)
├── docker-compose.yml    # Orchestration for local development and deployment
└── README.md
```

## Core Principles

- **Full independence**: Backend and frontend are separate applications. Each has its own source code, dependencies, build process, and configuration. There are no shared modules, monorepo tooling, or cross-references between them.
- **Separate containers**: Each application has its own `Dockerfile` in its directory. Each container can be built and run independently.
- **Docker Compose for orchestration**: A `docker-compose.yml` at the repository root wires the containers together. It handles port mapping, environment variables (like `BACKEND_URL` for the frontend), and startup ordering.
- **Independent local development**: Each application can be started on its own for development without Docker. The backend and frontend each have their own dev server and can be run in separate terminals.

## Docker

### Dockerfiles

Each application has a multi-stage `Dockerfile` in its own directory:

- **Backend (Java/Spring Boot)**: Build stage compiles with Maven/Gradle, runtime stage uses a minimal JRE image.
- **Frontend (TypeScript/Next.js)**: Build stage installs dependencies and compiles, runtime stage serves the built application with a minimal Node.js image.

Both Dockerfiles should:

- Use multi-stage builds to keep the final image small.
- Pin base image versions (e.g., `eclipse-temurin:25-alpine`, `node:24-alpine`).
- Run the application as a non-root user in the final stage.
- Expose only the application port.

### Docker Compose

The `docker-compose.yml` at the repository root:

- Defines one service per application (`backend`, `frontend`).
- Uses `build` with the application directory as context.
- Maps internal ports to configurable external ports via environment variables with defaults.
- Sets environment variables to connect services (e.g., `BACKEND_URL` on the frontend).
- Uses `depends_on` to define startup order where needed.

Example structure:

```yaml
services:
  backend:
    build: ./backend
    ports:
      - "${BACKEND_PORT:-9081}:8080"

  frontend:
    build: ./frontend
    environment:
      - BACKEND_URL=http://backend:8080
    ports:
      - "${FRONTEND_PORT:-4001}:3000"
    depends_on:
      - backend
```

## Communication Between Frontend and Backend

- The frontend communicates with the backend exclusively through HTTP APIs.
- In Docker Compose, the frontend uses the Docker service name to reach the backend (e.g., `http://backend:8080`).
- In local development, the frontend connects to the backend via `localhost` and the backend's dev port.
- API contracts should be clearly defined. Changes to the API should be coordinated between frontend and backend.

## What to Avoid

- Do not share code between frontend and backend (no shared `lib/` or common modules).
- Do not create a single Dockerfile that builds both applications.
- Do not use monorepo tools (Nx, Turborepo) to couple the build processes.
- Do not hardcode ports or URLs — use environment variables with sensible defaults.
