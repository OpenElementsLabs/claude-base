---
name: writing-migrations
description: Write safe, reversible database migrations. Use whenever the user wants to create, alter, or drop database schema — adding or removing tables, columns, indexes, or constraints — or asks how to write, order, name, or roll back a migration. Trigger on "write a migration", "add a column", "change the schema", "migrate the database", or similar.
---

# Writing Database Migrations

Produce forward-only-safe, reversible schema changes that deploy cleanly against a live database. This plugin also bundles a `db-tools` MCP server — use its `list_tables` and `run_query` tools to inspect the current schema before writing a migration, so the change matches reality.

## Instructions

1. **Inspect the current schema first.** Use the `db-tools` MCP tools (`list_tables`, `run_query`) to confirm the tables, columns, and constraints that exist. Never assume the schema; write the migration against what is actually there.
2. **One logical change per migration.** Keep each migration focused (e.g. "add `users.last_login_at`"). Do not combine unrelated schema changes in a single file.
3. **Name and order deterministically.** Use the project's existing naming convention (timestamp or sequential prefix, e.g. `20260704120000_add_last_login_at.sql`). Migrations must apply in a stable, sortable order.
4. **Always provide a rollback.** Write both an `up` (apply) and a `down` (revert) section. The `down` must exactly undo the `up`. If a change is genuinely irreversible (e.g. dropping data), say so explicitly and require confirmation.
5. **Make changes backward compatible for zero-downtime deploys.** Follow the expand/contract pattern:
   - Add new nullable columns or new tables first; backfill data in a separate step; only then add `NOT NULL` / drop old columns in a later migration.
   - Never rename a column in one step if old code is still running — add the new column, migrate reads/writes, then remove the old one.
6. **Guard large or locking operations.** Adding indexes or altering large tables can lock them. Prefer non-blocking variants where the database supports them (e.g. PostgreSQL `CREATE INDEX CONCURRENTLY`) and note that they cannot run inside a transaction.
7. **Wrap in a transaction when supported.** For databases and operations that allow it, run the migration in a single transaction so a failure leaves no partial state. Note the exceptions (concurrent index creation, some DDL on MySQL).
8. **Set safe defaults and constraints deliberately.** New `NOT NULL` columns need a default or a backfill before the constraint is enforced. Add foreign keys and unique constraints only after confirming existing data satisfies them (verify with `run_query`).
9. **Do not put secrets or environment-specific values in migrations.** No credentials, no hard-coded environment hostnames.
10. **State the verification step.** After writing the migration, describe how to verify it: re-run `list_tables`/`run_query`, and confirm both `up` and `down` succeed in a scratch environment.

## Output format

Deliver the migration as a file (or up/down pair) matching the project's migration tool and naming, followed by a short summary of: what changed, why it is reversible, and any deployment ordering or locking caveats.
