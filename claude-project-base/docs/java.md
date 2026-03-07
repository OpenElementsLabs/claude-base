# Java Conventions for Claude Code

## Code Style

- Do not use wildcard imports (`import java.util.*`). Always use explicit imports.
- Prefer `final` fields and local variables where possible.
- Use `final` on method parameters when the method body does not reassign them.
- Prefer records for simple data carriers.
- Use `var` for local variables only when the type is obvious from the right-hand side.
- Follow standard Java naming: `PascalCase` for classes, `camelCase` for methods/fields, `UPPER_SNAKE_CASE` for constants.

## Build Tools

- Respect the existing build tool (Maven or Gradle) — do not switch without explicit instruction.
- When adding dependencies, use the dependency management section (Maven `<dependencyManagement>` or Gradle version catalog) if one exists.
- Do not add dependencies that duplicate functionality already available in the project.

## Testing

- Use JUnit 5 (`org.junit.jupiter`) for tests.
- Use AssertJ for assertions (`org.assertj.core.api.Assertions`).
- Name test methods descriptively: `shouldReturnEmptyListWhenNoItemsExist()` or use `@DisplayName`.
- Use `@Nested` classes to group related tests within a test class.
- Use `@ParameterizedTest` for testing multiple inputs with the same logic.

## Logging

- Use SLF4J as the logging API (`org.slf4j.Logger`).
- Use parameterized logging (`log.info("Processing item {}", itemId)`) — never string concatenation.
- Log at appropriate levels: `ERROR` for failures that need attention, `WARN` for recoverable issues, `INFO` for significant events, `DEBUG` for development details.

## Null Handling

- Prefer `Optional<T>` for return types that may have no value. Do not use `Optional` as a field type or method parameter.
- Annotate parameters and fields with `@Nullable` or `@NonNull` to make intent explicit.
- Use `Objects.requireNonNull()` for early validation of non-null parameters.
- Never return `null` from a method that returns a collection — return an empty collection instead.
