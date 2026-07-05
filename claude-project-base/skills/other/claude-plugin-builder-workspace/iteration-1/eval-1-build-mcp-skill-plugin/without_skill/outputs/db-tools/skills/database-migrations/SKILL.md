---
name: database-migrations
description: Write safe, reversible database migrations. Use when the user wants to create, alter, or drop database tables, columns, indexes, or constraints; add a schema change; write an up/down migration; or plan a zero-downtime schema rollout.
---

# Database Migrations

Guidance for authoring database migrations that are safe to apply and safe to roll back.

## Instructions

1. Determine the migration framework in use before writing anything. Inspect the project for a `migrations/` directory, framework config (Flyway, Liquibase, Alembic, Prisma, Knex, Rails, Django, etc.), and the existing migration files. Match their naming and format exactly.
2. Identify the current schema state. Use the `db-tools` MCP server (`list_tables`, `describe_table`) to confirm the tables, columns, and constraints you are about to change actually exist as expected.
3. Give each migration a single, focused purpose. Do not bundle unrelated schema changes into one migration.
4. Write both directions. Provide an `up` (apply) and a `down` (revert) step. If a change is genuinely irreversible (e.g. dropping a column with data), state that explicitly in a comment and require confirmation before proceeding.
5. Make destructive changes reversible where possible. Prefer renaming to a `_deprecated` suffix over dropping; back up data into a temporary table before deletion.
6. Design for zero downtime when the table is large or the app is running:
   - Add new columns as nullable or with a default, then backfill in a separate step.
   - Add indexes concurrently where the database supports it (e.g. `CREATE INDEX CONCURRENTLY` in PostgreSQL) and outside a transaction.
   - Split rename/type changes into expand -> migrate -> contract phases across multiple deploys.
7. Never mix schema (DDL) changes and large data (DML) backfills in the same transaction; long-running backfills can hold locks and block the application.
8. Set explicit, safe defaults and `NOT NULL` constraints only after backfilling existing rows.
9. Always run the migration against a disposable copy of the database (or a transaction that is rolled back) before applying it to any shared environment.
10. Name migrations with a sortable timestamp or sequence prefix and a short description, following the project convention (for example `20260704_120000_add_email_to_users`).
11. Keep migrations idempotent-safe where the framework allows (`IF NOT EXISTS`, `IF EXISTS`) so re-running does not fail hard.
12. After writing the migration, summarize for the user: what it changes, whether it is reversible, its locking/downtime impact, and the exact command to run it.

## Checklist before declaring done

- Up and down steps are both present (or irreversibility is documented and confirmed).
- No unrelated changes are bundled together.
- Locking and downtime impact has been assessed for large tables.
- The migration name follows the project's existing convention.
- The change was validated against a non-production copy of the schema.
