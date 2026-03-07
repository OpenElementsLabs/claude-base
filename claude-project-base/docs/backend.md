# Backend Conventions for Claude Code

## Overview

Our backends are written in Java. This document covers conventions specific to backend applications. For general Java conventions, see [java.md](java.md).

## Frameworks

We use two frameworks for building backend applications:

- **[Spring Boot](https://spring.io/projects/spring-boot)** — The full-featured option. Use Spring Boot when the application needs a broad ecosystem (security, data access, messaging, etc.) and development speed matters more than minimal footprint.
- **[Helidon SE](https://helidon.io/)** — The lightweight option. Use Helidon SE for performant, lean backends where a small footprint and low startup time are important.

Both are valid choices depending on the project requirements. We aim to provide Open Elements base libraries (as dependencies) for both frameworks in the future.

### Libraries for Backend Frameworks

When building libraries that target backend applications, provide support for Spring Boot and Helidon SE as primary targets. Additionally, offer support for [Eclipse MicroProfile](https://microprofile.io/) and [Eclipse Jakarta EE](https://jakarta.ee/) where feasible, to broaden compatibility. For concrete backend applications, we typically do not use MicroProfile or Jakarta EE directly.

## REST APIs and OpenAPI

- Every backend that exposes REST endpoints must include a Swagger UI for interactive API exploration.
- Use [SpringDoc OpenAPI](https://springdoc.org/) (for Spring Boot) or an equivalent library to generate the OpenAPI specification automatically from code.
- Document every endpoint completely with OpenAPI annotations: summary, description, request/response schemas, status codes, and error responses.
- Use meaningful operation IDs and group endpoints with tags.
- Configure authentication information in the OpenAPI specification so that users can authorize directly in the Swagger UI to test protected endpoints. Include the supported security schemes (e.g., Bearer token, OAuth2) and their configuration.
- Ensure the OpenAPI spec stays in sync with the actual implementation — generate it from code rather than maintaining a separate spec file.
