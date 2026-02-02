---
name: database-schema-designer
description: Design robust, scalable database schemas for SQL and NoSQL databases. Provides normalization guidelines, indexing strategies, migration patterns, constraint design, and performance optimization. Ensures data integrity, query performance, and maintainable data models.
license: MIT
---

# Database Schema Designer

Design production-ready database schemas with best practices built-in.

## Triggers

| Trigger | Example |
|---------|---------|
| `design schema` | "design a schema for user authentication" |
| `database design` | "database design for multi-tenant SaaS" |
| `create tables` | "create tables for a blog system" |
| `schema for` | "schema for inventory management" |
| `model data` | "model data for real-time analytics" |
| `I need a database` | "I need a database for tracking orders" |
| `design NoSQL` | "design NoSQL schema for product catalog" |

## Quick Reference

| Task | Approach | Key Consideration |
|------|----------|-------------------|
| New schema | Normalize to 3NF first | Domain modeling over UI |
| SQL vs NoSQL | Access patterns decide | Read/write ratio matters |
| Primary keys | INT or UUID | UUID for distributed systems |
| Foreign keys | Always constrain | ON DELETE strategy critical |
| Indexes | FKs + WHERE columns | Column order matters |
| Migrations | Always reversible | Backward compatible first |

## Process

### Phase 1: Analyze

- Identify entities and relationships
- Determine access patterns (read-heavy vs write-heavy)
- Choose SQL or NoSQL based on requirements

### Phase 2: Design

- Normalize to 3NF (SQL) or determine embed/reference strategy (NoSQL)
- Define primary keys and foreign keys
- Choose appropriate data types -- read `references/data-types-reference.md` for type guides
- Add constraints -- read `references/constraints-and-relationships.md` for patterns

Read `references/normalization-guide.md` for 1NF/2NF/3NF rules and examples.

### Phase 3: Optimize

- Plan indexing strategy -- read `references/indexing-strategy.md` for when to index and composite index rules
- Consider denormalization for read-heavy queries
- Add timestamps (created_at, updated_at)

### Phase 4: Migrate

- Generate migration scripts (up + down)
- Ensure backward compatibility
- Plan zero-downtime deployment

Read `references/migration-patterns.md` for zero-downtime patterns and rollback strategies.

### NoSQL Design

For MongoDB, Firestore, and other document databases, read `references/nosql-design-patterns.md` for embedding vs referencing patterns and Firestore-specific design rules.

## Commands

| Command | When to Use |
|---------|-------------|
| `design schema for {domain}` | Start fresh -- full schema generation |
| `normalize {table}` | Fix existing table -- apply normalization rules |
| `add indexes for {table}` | Performance issues -- generate index strategy |
| `migration for {change}` | Schema evolution -- create reversible migration |
| `review schema` | Code review -- audit existing schema |

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| VARCHAR(255) everywhere | Wastes storage, hides intent | Size appropriately per field |
| FLOAT for money | Rounding errors | DECIMAL(10,2) |
| Missing FK constraints | Orphaned data | Always define foreign keys |
| No indexes on FKs | Slow JOINs | Index every foreign key |
| Storing dates as strings | Cannot compare/sort | DATE, TIMESTAMP types |
| Non-reversible migrations | Cannot rollback | Always write DOWN migration |

## Verification

After designing a schema, run through `references/schema-design-checklist.md` to verify completeness.

## Reference Files

| File | Contents |
|------|----------|
| `references/schema-design-checklist.md` | Pre-design, table design, and deployment checklist |
| `references/normalization-guide.md` | 1NF/2NF/3NF explanations, examples, denormalization guide |
| `references/data-types-reference.md` | String, numeric, date/time, JSON type guides |
| `references/indexing-strategy.md` | When to index, composite indexes, B-tree vs hash, EXPLAIN |
| `references/constraints-and-relationships.md` | PKs, FKs, CHECK, UNIQUE, relationship patterns |
| `references/nosql-design-patterns.md` | MongoDB/Firestore embedding vs referencing |
| `references/migration-patterns.md` | Zero-downtime migrations, rollback strategies |
| `assets/templates/migration-template.sql` | SQL migration file template |
