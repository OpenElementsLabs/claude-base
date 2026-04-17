---
name: modern-java
license: Apache-2.0
metadata:
  source: https://github.com/open-elements/claude-base
  author: Open Elements
description: Write idiomatic modern Java (11–25) by actively using newer language features and APIs instead of legacy patterns. Covers text blocks, records, sealed classes, pattern matching (instanceof, switch, record patterns, primitive patterns), unnamed variables, sequenced collections, structured concurrency, scoped values, stream gatherers, flexible constructor bodies, module imports, Markdown documentation comments, code snippets in Javadoc, and modern API additions (HttpClient, Stream.toList, String methods, RandomGenerator, Foreign Function & Memory API, cryptography APIs including EdDSA, KEM, ML-KEM, ML-DSA, KDF, PEM encoding, etc.). Trigger this skill whenever writing or reviewing Java code to ensure modern idioms are used instead of pre-Java-11 patterns.
---

# Modern Java

Write idiomatic Java by leveraging language features and APIs introduced in Java 11 through 25. Most training data and internet examples use Java 8–11 patterns. This skill ensures that generated code uses the best available constructs for the target Java version.

## Instructions

### 1. Determine the target Java version

Before writing code, check the project's Java version:

- Look at `pom.xml` (`<java.version>`, `<maven.compiler.release>`, `<maven.compiler.source>`).
- Look at `build.gradle` / `build.gradle.kts` (`sourceCompatibility`, `toolchain`).
- Look at `.sdkmanrc` or `Dockerfile` base images.

Only use features available in the project's target version. When the version is unclear, ask the user.

### 2. Language features by version

#### Java 11 — Local variable syntax for lambda parameters

```java
// Old: explicit types or no annotation possible
(String x, String y) -> x + y

// Modern: var in lambdas enables annotations
(@NonNull var x, @NonNull var y) -> x + y
```

#### Java 14 — Switch expressions

Replace traditional switch statements with switch expressions that return values.

```java
// Old
String label;
switch (status) {
    case ACTIVE:
        label = "Active";
        break;
    case INACTIVE:
        label = "Inactive";
        break;
    default:
        label = "Unknown";
        break;
}

// Modern
String label = switch (status) {
    case ACTIVE -> "Active";
    case INACTIVE -> "Inactive";
    default -> "Unknown";
};
```

Use `yield` for multi-line blocks:

```java
String description = switch (status) {
    case ACTIVE -> "Active";
    case PENDING -> {
        log.info("Pending status found");
        yield "Pending Review";
    }
    default -> "Unknown";
};
```

#### Java 15 — Text blocks

Replace string concatenation or `\n`-littered strings with text blocks for multi-line content.

```java
// Old
String json = "{\n" +
    "  \"name\": \"Alice\",\n" +
    "  \"age\": 30\n" +
    "}";

// Modern
String json = """
        {
          "name": "Alice",
          "age": 30
        }
        """;
```

Use text blocks for SQL, JSON, HTML, XML, log messages, and any multi-line string. Indentation is managed by the position of the closing `"""`.

#### Java 16 — Records

Use records for immutable data carriers instead of classes with boilerplate.

```java
// Old (25+ lines)
public final class Point {
    private final int x;
    private final int y;
    public Point(int x, int y) { this.x = x; this.y = y; }
    public int x() { return x; }
    public int y() { return y; }
    @Override public boolean equals(Object o) { ... }
    @Override public int hashCode() { ... }
    @Override public String toString() { ... }
}

// Modern (1 line)
public record Point(int x, int y) {}
```

Use the compact constructor for validation:

```java
public record Range(int start, int end) {
    public Range {
        if (start > end) {
            throw new IllegalArgumentException("start must be <= end");
        }
    }
}
```

Defensive-copy mutable components:

```java
public record Team(String name, List<String> members) {
    public Team {
        Objects.requireNonNull(name, "name must not be null");
        members = List.copyOf(members);
    }
}
```

#### Java 16 — Pattern matching for instanceof

Eliminate explicit casts after `instanceof`.

```java
// Old
if (obj instanceof String) {
    String s = (String) obj;
    System.out.println(s.length());
}

// Modern
if (obj instanceof String s) {
    System.out.println(s.length());
}

// Also works with negation
if (!(obj instanceof String s)) {
    return;
}
// s is in scope here
System.out.println(s.length());
```

#### Java 17 — Sealed classes and interfaces

Use sealed types when the set of subtypes is known and finite.

```java
public sealed interface Shape permits Circle, Rectangle, Triangle {}

public record Circle(double radius) implements Shape {}
public record Rectangle(double width, double height) implements Shape {}
public record Triangle(double a, double b, double c) implements Shape {}
```

Sealed types enable exhaustive switch expressions (no `default` needed when all cases covered).

#### Java 21 — Pattern matching for switch

Combine sealed types and pattern matching for powerful, type-safe branching.

```java
// Old: instanceof chains
if (shape instanceof Circle c) {
    return Math.PI * c.radius() * c.radius();
} else if (shape instanceof Rectangle r) {
    return r.width() * r.height();
} else if (shape instanceof Triangle t) {
    double s = (t.a() + t.b() + t.c()) / 2;
    return Math.sqrt(s * (s - t.a()) * (s - t.b()) * (s - t.c()));
} else {
    throw new IllegalArgumentException("Unknown shape");
}

// Modern
return switch (shape) {
    case Circle c -> Math.PI * c.radius() * c.radius();
    case Rectangle r -> r.width() * r.height();
    case Triangle t -> {
        double s = (t.a() + t.b() + t.c()) / 2;
        yield Math.sqrt(s * (s - t.a()) * (s - t.b()) * (s - t.c()));
    }
};
```

Use guarded patterns with `when`:

```java
String format(Object obj) {
    return switch (obj) {
        case Integer i when i < 0 -> "negative: " + i;
        case Integer i -> "positive: " + i;
        case String s when s.isBlank() -> "(blank)";
        case String s -> s;
        case null -> "null";
        default -> obj.toString();
    };
}
```

`null` can be handled directly in switch (no more `NullPointerException` before the switch).

#### Java 21 — Record patterns

Destructure records directly in pattern matching.

```java
// Old
if (obj instanceof Point p) {
    int x = p.x();
    int y = p.y();
    System.out.println(x + ", " + y);
}

// Modern
if (obj instanceof Point(int x, int y)) {
    System.out.println(x + ", " + y);
}
```

Nested record patterns:

```java
record Point(int x, int y) {}
record Line(Point start, Point end) {}

// Deep destructuring
if (obj instanceof Line(Point(int x1, int y1), Point(int x2, int y2))) {
    double length = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
}
```

Record patterns in switch:

```java
String describe(Shape shape) {
    return switch (shape) {
        case Circle(double r) when r > 100 -> "large circle";
        case Circle(double r) -> "circle with radius " + r;
        case Rectangle(double w, double h) when w == h -> "square " + w;
        case Rectangle(double w, double h) -> w + "x" + h + " rectangle";
    };
}
```

#### Java 21 — Sequenced collections

Use the new sequenced collection interfaces for ordered access.

```java
// Old
list.get(0);                        // first element
list.get(list.size() - 1);          // last element
var it = set.iterator();
it.next();                          // first of LinkedHashSet

// Modern
list.getFirst();
list.getLast();
set.getFirst();

// Also: addFirst, addLast, removeFirst, removeLast, reversed
list.reversed().forEach(System.out::println);
```

`SequencedCollection`, `SequencedSet`, and `SequencedMap` are new interfaces in the hierarchy.

For maps: `sequencedMap.firstEntry()`, `sequencedMap.lastEntry()`, `sequencedMap.reversed()`.

#### Java 21 — Virtual threads

Use virtual threads for I/O-bound concurrent work instead of platform threads or thread pools.

```java
// Old
ExecutorService pool = Executors.newFixedThreadPool(100);
pool.submit(() -> handleRequest(request));

// Modern: virtual threads for I/O tasks
ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
executor.submit(() -> handleRequest(request));

// Or directly
Thread.startVirtualThread(() -> handleRequest(request));

// With Thread.Builder
Thread.ofVirtual().name("worker-", 0).start(() -> handleRequest(request));
```

Important rules for virtual threads:

- Use for I/O-bound work (HTTP calls, database queries, file I/O). Not beneficial for CPU-bound work.
- Do not pool virtual threads — create a new one per task.
- Avoid `synchronized` blocks that do I/O inside — use `ReentrantLock` instead (to avoid pinning the carrier thread).
- `Thread.sleep()` and blocking I/O work correctly and efficiently on virtual threads.

#### Java 22 — Unnamed variables and patterns

Use `_` for variables that are intentionally unused.

```java
// Old
try {
    // ...
} catch (NumberFormatException ignored) {
    // exception intentionally ignored
}
map.forEach((key, value) -> processValue(value)); // key unused

// Modern
try {
    // ...
} catch (NumberFormatException _) {
    // exception intentionally ignored
}
map.forEach((_, value) -> processValue(value));

// In pattern matching
switch (obj) {
    case Point(int x, _) -> "x=" + x;  // y not needed
    default -> "other";
}
```

#### Java 23 — Primitive types in patterns (preview, standard in 25)

Pattern matching extends to primitive types, eliminating manual casts and range checks.

```java
// Modern (Java 25)
return switch (statusCode) {
    case 200 -> "OK";
    case 301 -> "Moved";
    case 404 -> "Not Found";
    case int code when code >= 500 -> "Server Error: " + code;
    case int code -> "Other: " + code;
};
```

#### Java 23 — Module import declarations (preview, standard in 25)

Import all exported packages of a module with a single declaration.

```java
// Old
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

// Modern (Java 25)
import module java.base;
```

#### Java 24 — Flexible constructor bodies

Code can execute before `super()` or `this()` calls for validation and transformation. Previously all pre-super code was illegal.

```java
// Old: had to validate after super or use static helper
public class PositiveRange extends Range {
    public PositiveRange(int start, int end) {
        super(start, end); // what if start < 0?
        if (start < 0) throw new IllegalArgumentException(); // too late if super has side effects
    }
}

// Modern (Java 24)
public class PositiveRange extends Range {
    public PositiveRange(int start, int end) {
        if (start < 0) throw new IllegalArgumentException("start must be >= 0");
        super(start, end);
    }
}
```

Restriction: code before `super()`/`this()` cannot access `this` (cannot read fields, call instance methods, or use `this` as an argument).

#### Java 18 — Code snippets in Javadoc (@snippet)

Replace `<pre>{@code ...}</pre>` blocks with the `{@snippet}` tag for code examples in documentation.

```java
// Old: error-prone, no validation, no syntax highlighting
/**
 * Example usage:
 * <pre>{@code
 * List<String> list = List.of("a", "b");
 * }</pre>
 */

// Modern: validated, supports highlighting and regions
/**
 * Example usage:
 * {@snippet :
 * List<String> list = List.of("a", "b");   // @highlight substring="List.of"
 * }
 */
```

External snippets reference real compilable code from separate files:

```java
/**
 * {@snippet file="ShowExample.java" region="usage"}
 */
```

Where `ShowExample.java` in the `snippet-files` directory contains:

```java
public class ShowExample {
    void demo() {
        // @start region="usage"
        List<String> list = List.of("a", "b");
        // @end
    }
}
```

#### Java 23 — Markdown documentation comments

Use `///` with Markdown syntax instead of `/** */` with HTML and JavaDoc tags.

```java
// Old: HTML markup, verbose
/**
 * Returns the user with the given <em>id</em>.
 * <p>
 * The lookup follows these steps:
 * <ul>
 *   <li>Check the cache</li>
 *   <li>Query the database</li>
 * </ul>
 *
 * @param id the user ID
 * @return the user, or {@code null} if not found
 * @see UserRepository
 */

// Modern: Markdown syntax, cleaner
/// Returns the user with the given _id_.
///
/// The lookup follows these steps:
///
/// - Check the cache
/// - Query the database
///
/// @param id the user ID
/// @return the user, or `null` if not found
/// @see UserRepository
```

Key differences:
- `///` line comments instead of `/** */` block comments.
- Markdown for formatting: `_italic_`, `**bold**`, `` `code` ``, `-` for lists, blank lines for paragraphs.
- Links to API elements use Markdown reference links: `[List]` links to `java.util.List` (if imported), `[String#chars()]` links to the method.
- Tables use GitHub Flavored Markdown pipe syntax.
- JavaDoc block tags (`@param`, `@return`, `@see`, `@throws`) remain unchanged.
- Fenced code blocks (`` ``` ``) replace `{@snippet}` for simple inline examples.

#### Java 25 — Stable features arriving

Java 25 (September 2025) finalizes several important features:

- **Primitive types in patterns** — full pattern matching support for primitives in `instanceof` and `switch`.
- **Module import declarations** — `import module java.base;` to import all public types from a module.
- **Structured concurrency** — `StructuredTaskScope` for managing concurrent subtasks as a unit (see API section below).
- **Scoped values** — `ScopedValue` as a modern replacement for `ThreadLocal` (see API section below).
- **Stream gatherers** — custom intermediate stream operations via `Stream.gather()` (see API section below).
- **Compact source files** (Simple source files) — allows writing Java programs without explicitly declaring a class. The implicit class has an implicit `main` method if a top-level `main` method is present. Primarily for learning and scripting.

### 3. Modern API additions by version

#### Java 11 — String methods

```java
"  hello  ".strip()          // "hello" (Unicode-aware, prefer over trim())
"  hello  ".stripLeading()   // "hello  "
"  hello  ".stripTrailing()  // "  hello"
"  ".isBlank()               // true (better than trim().isEmpty())
"line1\nline2".lines()       // Stream<String> of lines
"ha".repeat(3)               // "hahaha"
```

Always prefer `strip()` over `trim()` — it handles Unicode whitespace correctly.

#### Java 11 — HttpClient

Replace `HttpURLConnection` and third-party HTTP clients for simple use cases.

```java
HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create("https://api.example.com/data"))
        .header("Accept", "application/json")
        .GET()
        .build();

HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
System.out.println(response.body());

// Async
client.sendAsync(request, HttpResponse.BodyHandlers.ofString())
        .thenApply(HttpResponse::body)
        .thenAccept(System.out::println);
```

#### Java 11 — Files convenience methods

```java
// Read/write strings directly
String content = Files.readString(Path.of("file.txt"));
Files.writeString(Path.of("output.txt"), content);

// With charset
String content = Files.readString(path, StandardCharsets.UTF_8);
```

#### Java 12 — String and Collectors

```java
// String.indent and transform
"hello".indent(4)                    // "    hello\n"
"42".transform(Integer::parseInt)    // 42

// Collectors.teeing — combine two collectors
var result = stream.collect(Collectors.teeing(
        Collectors.counting(),
        Collectors.summingInt(Item::price),
        (count, sum) -> new Summary(count, sum)
));
```

#### Java 16 — Stream.toList()

```java
// Old
List<String> names = stream.collect(Collectors.toList());

// Modern — returns unmodifiable list
List<String> names = stream.toList();
```

Note: `Stream.toList()` returns an unmodifiable list (unlike `Collectors.toList()`). Use `Collectors.toCollection(ArrayList::new)` if you need a mutable list.

#### Java 16 — mapMulti

Replace `flatMap` with `mapMulti` when the mapping is conditional or produces few elements.

```java
// Old: flatMap creates intermediate streams
stream.flatMap(x -> x.isValid() ? Stream.of(x.value()) : Stream.empty());

// Modern: mapMulti avoids stream overhead
stream.<String>mapMulti((x, consumer) -> {
    if (x.isValid()) {
        consumer.accept(x.value());
    }
});
```

#### Java 17 — HexFormat

```java
// Old
String hex = String.format("%02x", byteValue);
byte[] bytes = DatatypeConverter.parseHexBinary(hexString); // removed in Java 11

// Modern
HexFormat hex = HexFormat.of();
String hexString = hex.formatHex(byteArray);
byte[] bytes = hex.parseHex(hexString);

// With delimiters
HexFormat.ofDelimiter(":").formatHex(macAddress);  // "aa:bb:cc:dd:ee:ff"
```

#### Java 18 — Simple web server (jwebserver)

`jwebserver` CLI tool for quick static file serving during development. Also available programmatically:

```java
var server = SimpleFileServer.createFileServer(
        new InetSocketAddress(8080),
        Path.of("/var/www"),
        SimpleFileServer.OutputLevel.INFO
);
server.start();
```

#### Java 21 — Structured concurrency

Manage concurrent subtasks as a unit — if one fails, the others are cancelled.

```java
// Old: manual CompletableFuture management, error-prone cleanup
CompletableFuture<User> userFuture = CompletableFuture.supplyAsync(() -> fetchUser(id));
CompletableFuture<List<Order>> ordersFuture = CompletableFuture.supplyAsync(() -> fetchOrders(id));
// If fetchOrders fails, fetchUser keeps running...

// Modern (Java 25 — stable)
try (var scope = StructuredTaskScope.open()) {
    Subtask<User> user = scope.fork(() -> fetchUser(id));
    Subtask<List<Order>> orders = scope.fork(() -> fetchOrders(id));
    scope.join();
    return new UserProfile(user.get(), orders.get());
}
// All subtasks complete or are cancelled together
```

With failure handling policies:

```java
// Fail on first error (ShutdownOnFailure replacement via Joiner)
try (var scope = StructuredTaskScope.open(Joiner.awaitAllSuccessfulOrThrow())) {
    Subtask<User> user = scope.fork(() -> fetchUser(id));
    Subtask<List<Order>> orders = scope.fork(() -> fetchOrders(id));
    scope.join();
    return new UserProfile(user.get(), orders.get());
}

// Race: return first successful result
try (var scope = StructuredTaskScope.open(Joiner.anySuccessfulResultOrThrow())) {
    scope.fork(() -> fetchFromPrimary(id));
    scope.fork(() -> fetchFromMirror(id));
    return scope.join();  // first successful result
}
```

#### Java 21 — Scoped values

Replace `ThreadLocal` with `ScopedValue` for sharing immutable data across call stacks, especially with virtual threads.

```java
// Old: ThreadLocal leaks, mutable, must be cleaned up
static final ThreadLocal<User> CURRENT_USER = new ThreadLocal<>();
CURRENT_USER.set(user);
try {
    process();
} finally {
    CURRENT_USER.remove();
}

// Modern (Java 25 — stable)
static final ScopedValue<User> CURRENT_USER = ScopedValue.newInstance();

ScopedValue.runWhere(CURRENT_USER, user, () -> {
    process();
});
// Automatically scoped, no cleanup needed, immutable within scope

// Reading
User user = CURRENT_USER.get();  // throws if not bound
CURRENT_USER.orElse(defaultUser);
```

Advantages over ThreadLocal: no memory leaks, immutable bindings, works naturally with virtual threads and structured concurrency, inheritable by child scopes.

#### Java 22 — Stream gatherers

Create custom intermediate stream operations with `Stream.gather()`.

```java
// Built-in gatherers (Java 25 — stable, from java.util.stream.Gatherers)

// Fixed-size windows
stream.gather(Gatherers.windowFixed(3))
      .forEach(window -> System.out.println(window));
// [1,2,3], [4,5,6], [7,8,9]

// Sliding windows
stream.gather(Gatherers.windowSliding(3))
      .forEach(window -> System.out.println(window));
// [1,2,3], [2,3,4], [3,4,5]

// Fold (stateful reduction as intermediate operation)
stream.gather(Gatherers.fold(() -> 0, Integer::sum));

// Scan (running accumulation)
stream.gather(Gatherers.scan(() -> 0, Integer::sum))
      .toList();
// [1, 3, 6, 10, 15] for input [1, 2, 3, 4, 5]

// mapConcurrent — process elements concurrently with virtual threads
stream.gather(Gatherers.mapConcurrent(10, this::fetchFromApi))
      .toList();
```

Custom gatherer example:

```java
// Distinct by key (not available in standard Stream API)
static <T, K> Gatherer<T, ?, T> distinctBy(Function<T, K> keyExtractor) {
    return Gatherer.ofSequential(
            HashSet::new,
            (seen, element, downstream) -> {
                if (seen.add(keyExtractor.apply(element))) {
                    return downstream.push(element);
                }
                return true;
            }
    );
}

// Usage
users.stream()
     .gather(distinctBy(User::email))
     .toList();
```

#### Java 21 — Other notable additions

```java
// String: StringBuilder and StringBuffer indexOf with range
// Character: emoji support
Character.isEmoji('😀');       // true
Character.isEmojiComponent(c); // true for skin tone modifiers etc.

// Math: clamp
Math.clamp(value, min, max);   // instead of Math.max(min, Math.min(max, value))

// Collections: unmodifiable sequenced views
Collections.unmodifiableSequencedCollection(collection);
Collections.unmodifiableSequencedSet(set);
Collections.unmodifiableSequencedMap(map);

// Repeat for StringBuilder
new StringBuilder().repeat("abc", 3);  // "abcabcabc"
```

#### Java 22 — Class-File API

For tools and frameworks that generate bytecode, `java.lang.classfile` replaces ASM/Byte Buddy for standard bytecode generation.

#### Java 24 — Deprecation of sun.misc.Unsafe memory access

`sun.misc.Unsafe` memory-access methods are deprecated for removal. Use the Foreign Function & Memory API (`java.lang.foreign`) or `VarHandle` instead.

### 4. Migration patterns — old to modern

Always apply these substitutions when you encounter legacy patterns:

| Legacy pattern | Modern replacement | Since |
|---|---|---|
| `instanceof` + explicit cast | Pattern matching `instanceof` | 16 |
| if/else instanceof chains | Pattern matching `switch` | 21 |
| Switch statement with break | Switch expression with `->` | 14 |
| String concatenation (multi-line) | Text blocks `"""` | 15 |
| POJO with getters/equals/hashCode | `record` | 16 |
| `list.get(list.size()-1)` | `list.getLast()` | 21 |
| `stream.collect(Collectors.toList())` | `stream.toList()` | 16 |
| `"".trim()` | `"".strip()` | 11 |
| `"".trim().isEmpty()` | `"".isBlank()` | 11 |
| `new BufferedReader(new InputStreamReader(...)).lines()` | `Files.readString(path)` | 11 |
| `HttpURLConnection` | `HttpClient` | 11 |
| `DatatypeConverter.parseHexBinary` | `HexFormat` | 17 |
| `Math.max(min, Math.min(max, val))` | `Math.clamp(val, min, max)` | 21 |
| `ThreadLocal` for request-scoped data | `ScopedValue` | 25 |
| Thread pools for I/O concurrency | Virtual threads | 21 |
| `CompletableFuture` for concurrent subtasks | `StructuredTaskScope` | 25 |
| `flatMap` for simple conditional mapping | `mapMulti` | 16 |
| Unused catch variable `ignored` | Unnamed variable `_` | 22 |
| Validation after `super()` call | Pre-super validation | 24 |

### 5. Usage rules

1. **Always check the project's Java version** before using any feature. Do not use Java 21 features in a Java 17 project.
2. **Prefer the modern pattern** whenever the project version supports it. Do not write legacy-style code on modern Java.
3. **Do not mix styles** — if a file uses switch expressions, do not add a switch statement. Keep the style consistent.
4. **Records replace data classes** — any class whose sole purpose is carrying data should be a record (unless it needs mutability or inheritance).
5. **Text blocks for all multi-line strings** — SQL, JSON, HTML, XML, log messages, error messages.
6. **Pattern matching first** — use `instanceof` patterns and switch patterns instead of explicit casts and if/else chains.
7. **Virtual threads for I/O** — when writing concurrent I/O code on Java 21+, default to virtual threads.
8. **Sequenced collection methods** — always use `getFirst()`/`getLast()` instead of index-based access for first/last elements on Java 21+.
9. **`Stream.toList()`** — always use instead of `Collectors.toList()` on Java 16+ unless a mutable list is needed.
10. **`strip()` over `trim()`** — always prefer `strip()` on Java 11+.

### 6. Review checklist

When reviewing Java code, check for these modernization opportunities:

- [ ] Are `instanceof` checks followed by explicit casts? (Use pattern matching)
- [ ] Are there multi-way `if/else instanceof` chains? (Use pattern matching switch)
- [ ] Are switch statements used where switch expressions would work?
- [ ] Are multi-line strings using concatenation instead of text blocks?
- [ ] Are there data-carrier classes that should be records?
- [ ] Is `Collectors.toList()` used instead of `Stream.toList()`?
- [ ] Is `trim()` used instead of `strip()`?
- [ ] Are first/last element accesses using index arithmetic instead of `getFirst()`/`getLast()`?
- [ ] Are `ThreadLocal`s used where `ScopedValue` would be better? (Java 25+)
- [ ] Is thread pool-based concurrency used for I/O instead of virtual threads? (Java 21+)
- [ ] Are `CompletableFuture` patterns used where structured concurrency would be cleaner? (Java 25+)
- [ ] Are there unused variables that should use `_`? (Java 22+)
- [ ] Is `HttpURLConnection` used instead of `HttpClient`? (Java 11+)
- [ ] Are byte arrays formatted to hex manually instead of using `HexFormat`? (Java 17+)
- [ ] Are sealed types applicable for known type hierarchies? (Java 17+)
