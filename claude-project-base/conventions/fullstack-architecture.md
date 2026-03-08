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

- **IMPORTANT — Full independence**: Backend and frontend are separate applications. Each has its own source code, dependencies, build process, and configuration. There are no shared modules, monorepo tooling, or cross-references between them.
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

### Common Docker Compose Commands

Document the following commands in the project README:

- **Start with rebuild**: `docker-compose up --build` — Always use `--build` to ensure code changes are reflected in the containers. Without this flag, Docker Compose reuses cached images and changes are not visible.
- **Stop**: `docker-compose down` — Stops and removes containers.
- **Stop and remove volumes**: `docker-compose down -v` — Also removes persistent data (databases, etc.).

## Communication Between Frontend and Backend

- The frontend communicates with the backend exclusively through HTTP APIs.
- **IMPORTANT**: The frontend application must never call the backend directly from the browser. Instead, route all API calls through the frontend's server-side layer. This avoids CORS issues and prevents exposing internal backend URLs to the client. Note: the backend's Swagger UI is accessed directly by developers for API exploration — this rule applies to the frontend application's API communication only.
- **For Next.js**: Use [Next.js Rewrites](https://nextjs.org/docs/app/api-reference/config/next-config-js/rewrites) or [API Routes (Route Handlers)](https://nextjs.org/docs/app/building-your-application/routing/route-handlers) to proxy requests to the backend. The frontend's server process knows the backend URL (via `BACKEND_URL` environment variable), but the browser only talks to the frontend's own origin.
- In Docker Compose, the frontend server-side proxy reaches the backend via the Docker service name (e.g., `http://backend:8080`). The browser only communicates with the frontend container.
- In local development, the frontend proxy connects to the backend via `localhost` and the backend's dev port.
- Do not configure CORS on the backend to allow frontend origins as a workaround — use the proxy approach instead.
- API contracts should be clearly defined. Changes to the API should be coordinated between frontend and backend.

## Pinned Tool Versions

Pin exact versions of runtimes and build tools in the repository so that every developer and CI environment uses the same versions.

- **Java**: Use a `.sdkmanrc` file in the backend directory to pin the Java version (e.g., `java=25`). Developers activate it with `sdk env install`.
- **Node.js**: Use a `.nvmrc` file in the frontend directory to pin the Node.js version (e.g., `v22.19.0`). Developers activate it with `nvm install`.
- **Build tool wrappers**: Use the Maven Wrapper (`mvnw`) or Gradle Wrapper (`gradlew`) so the build tool version is committed to the repository and does not need to be installed separately.
- Do not rely on globally installed tool versions. The repository must define everything needed to build and run.

## Configuration

- **IMPORTANT**: Both frontend and backend must be configurable via environment variables. All environment-specific values (database URLs, API keys, feature flags, external service URLs) must be read from environment variables — never hardcoded.
- For local development, use a `.env` file at the repository root (or per application directory) to define environment variables. Docker Compose loads `.env` files automatically.
- Add `.env` to `.gitignore`. Provide a `.env.example` file with all required variables and sensible defaults or placeholder values as documentation.
- In hosted environments (Coolify, cloud platforms, CI/CD), set environment variables directly in the platform configuration instead of using `.env` files.
- Design configuration so that the same container image can run in any environment (local, test, production) — only the environment variables change.

## What to Avoid

- **IMPORTANT**: Do not share code between frontend and backend (no shared `lib/` or common modules).
- Do not create a single Dockerfile that builds both applications.
- Do not use monorepo tools (Nx, Turborepo) to couple the build processes.
- **IMPORTANT**: Do not hardcode ports or URLs — use environment variables with sensible defaults.
