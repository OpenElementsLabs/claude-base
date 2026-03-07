# Java Conventions for Claude Code

## Code Style

- Do not use wildcard imports (`import java.util.*`). Always use explicit imports.
- Prefer `final` fields and local variables where possible.
- Use `final` on method parameters when the method body does not reassign them.
- Prefer records for immutable data carriers. Use classes with `final` fields and getters for types that mix mutable and
  immutable state.
- Do not use `var`
- Follow standard Java naming: `PascalCase` for classes, `camelCase` for methods/fields, `UPPER_SNAKE_CASE` for
  constants.
- Do not use Lombok. Use modern Java features (records, pattern matching) instead.
- Always override `equals`, `hashCode`, and `toString` together for non-record classes. Use `Objects.equals()` and
  `Objects.hash()` as helpers.
- Format `toString` as `ClassName[field1=value1, field2=value2]`. Never expose sensitive data (passwords, tokens) in
  `toString`.

## Build Tools

- Respect the existing build tool (Maven or Gradle) — do not switch without explicit instruction.
- We always prefer Maven over Gradle.
- When adding dependencies, use the dependency management section (Maven `<dependencyManagement>` or Gradle version
  catalog) if one exists.
- Do not add dependencies that duplicate functionality already available in the project.

## Testing

- Use JUnit 5 (`org.junit.jupiter`) for tests.
- Use AssertJ for assertions (`org.assertj.core.api.Assertions`).
- Name test methods descriptively: `shouldReturnEmptyListWhenNoItemsExist()` or use `@DisplayName`.
- Use `@Nested` classes to group related tests within a test class.
- Use `@ParameterizedTest` for testing multiple inputs with the same logic.
- Use "//GIVEN //WHEN //THEN" syntax for all tests

## Logging

- Use SLF4J as the logging API (`org.slf4j.Logger`).
- For low level code System.Logger is preferred.
- Use parameterized logging (`log.info("Processing item {}", itemId)`) — never string concatenation.
- Log at appropriate levels: `ERROR` for failures that need attention, `WARN` for recoverable issues, `INFO` for
  significant events, `DEBUG` for development details.

## Null Handling

- Prefer `Optional<T>` for return types that may have no value. Do not use `Optional` as a field type or method
  parameter.
- Annotate parameters and fields with `@Nullable` or `@NonNull` (using `org.jspecify` when available) to make intent
  explicit.
- Use `Objects.requireNonNull(param, "paramName must not be null")` for early validation of non-null parameters — always
  include the parameter name in the message.
- Never return `null` from a method that returns a collection — return an empty collection instead.

## Collections

- Always copy incoming collections before storing them to avoid external mutation (`List.copyOf()`, `Set.copyOf()`,
  `Map.copyOf()`).
- Return unmodifiable collections from public API methods.
- Use thread-safe backing types (`CopyOnWriteArrayList`, `ConcurrentHashMap`) when collections may be accessed from
  multiple threads.

## Immutability and Validation

- Prefer immutable objects. Use records for fully immutable types.
- Validate constructor and setter arguments early. Throw `IllegalArgumentException` for constraint violations (min/max
  values, string length, patterns).
- Use `java.time` types (`Instant`, `LocalDate`, `Duration`, etc.) for all date and time handling — never
  `java.util.Date` or `java.util.Calendar`.
- Use `BigDecimal` for precise decimal values (financial calculations, etc.) — never `float` or `double`.

## Factory Methods

- Prefer static factory methods on the type itself over separate factory classes (e.g., `Money.of(amount, currency)`
  instead of `MoneyFactory.create()`).
- Name factory methods descriptively: `of`, `from`, `create`, `valueOf`.

## Java Module System

- Use the Java Platform Module System (JPMS) for standalone libraries whenever possible. Define a `module-info.java`
  that exports only the public API packages and keeps implementation packages hidden.
- Only export packages that contain the public API. Internal and implementation packages should not be exported.
- Use `requires` to declare module dependencies explicitly rather than relying on the classpath.
- Some frameworks (e.g., Spring Boot) have limited JPMS support. In those projects, skip module-info if it causes
  friction — but still structure packages as if modules were in use (separate API and implementation packages).

## Asynchronous Code

- Use `CompletionStage<T>` or `CompletableFuture<T>` for asynchronous return types.
- When providing async methods, consider offering synchronous alternatives that accept a timeout with `TimeUnit`.
