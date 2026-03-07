# Backend Conventions for Claude Code

## Overview

Our backends are written in Java, typically using Spring Boot. This document covers conventions specific to backend applications. For general Java conventions, see [java.md](java.md).

## REST APIs and OpenAPI

- Every backend that exposes REST endpoints must include a Swagger UI for interactive API exploration.
- Use [SpringDoc OpenAPI](https://springdoc.org/) (for Spring Boot) or an equivalent library to generate the OpenAPI specification automatically from code.
- Document every endpoint completely with OpenAPI annotations: summary, description, request/response schemas, status codes, and error responses.
- Use meaningful operation IDs and group endpoints with tags.
- Configure authentication information in the OpenAPI specification so that users can authorize directly in the Swagger UI to test protected endpoints. Include the supported security schemes (e.g., Bearer token, OAuth2) and their configuration.
- Ensure the OpenAPI spec stays in sync with the actual implementation — generate it from code rather than maintaining a separate spec file.
