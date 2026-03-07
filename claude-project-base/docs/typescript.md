# TypeScript Conventions for Claude Code

## Code Style

- Enable `strict` mode in `tsconfig.json`. Do not weaken strict checks without explicit justification.
- Use explicit type annotations for function parameters and return types. Rely on inference for local variables.
- Prefer `interface` over `type` for object shapes unless you need union types or mapped types.
- Use `const` by default. Use `let` only when reassignment is needed. Never use `var`.
- Prefer `readonly` for properties that should not be reassigned after initialization.
- Follow standard naming: `PascalCase` for types/interfaces/classes, `camelCase` for variables/functions, `UPPER_SNAKE_CASE` for constants.

## Package Manager

- Respect the existing package manager in the project (`npm`, `yarn`, or `pnpm`) — do not switch without explicit instruction.
- Use the lockfile that matches the package manager (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`).
- Do not add dependencies that duplicate functionality already available in the project.

## Testing

- Use the testing framework already present in the project (e.g., Jest, Vitest, or Node test runner).
- Name test cases descriptively: `it('should return empty array when no items exist')`.
- Group related tests with `describe` blocks.
- Prefer `toEqual` for deep equality and `toBe` for reference/primitive equality.
- Mock external dependencies, not internal implementation details.

## Linting and Formatting

- Respect existing ESLint and Prettier configurations. Do not change rules without explicit instruction.
- Fix linting errors in code you write or modify. Do not add `eslint-disable` comments unless there is a clear justification.
- Run formatting before committing to keep diffs clean.

## Error Handling

- Use typed errors or custom error classes where appropriate.
- Avoid catching errors without handling them. At minimum, log the error.
- Prefer `unknown` over `any` in catch blocks: `catch (error: unknown)`.
