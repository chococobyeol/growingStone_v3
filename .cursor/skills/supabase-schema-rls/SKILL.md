---
name: supabase-schema-rls
description: Provides Supabase table design and RLS policy workflow for game features. Use when adding or reviewing Supabase schema, row level security, migration SQL, indexes, or server-trust validation boundaries.
---

# Supabase Schema + RLS

## Use This Skill When

- User mentions Supabase table/policy/migration changes.
- Implementing social features (share, like, ranking), inventory, auction, or profile data.
- Reviewing security boundaries between client and server.

## Security Baseline

1. Default deny with RLS enabled on all gameplay tables.
2. User-owned rows: allow `select/insert/update` only for `auth.uid() = user_id`.
3. Sensitive counters or settlement values: update via trusted backend path only.
4. Server time and authoritative calculations must not trust client clocks.

## Schema Design Defaults

- Use UUID primary keys.
- Include `created_at`, `updated_at`, and actor (`user_id`) when applicable.
- Add indexes for common filters: `user_id`, `created_at`, `week_key`, `stone_id`.
- Use explicit unique constraints for reaction tables (e.g., one like per user per target).

## Migration Workflow

1. Define table and constraints.
2. Enable RLS immediately.
3. Add minimal policies for required access patterns.
4. Add indexes based on expected query paths.
5. Verify with representative queries before rollout.

## Review Checklist

- [ ] Every new table has RLS enabled.
- [ ] Policies match product intent and block cross-user access.
- [ ] Unique/index constraints match ranking/feed query patterns.
- [ ] Write paths for sensitive values are server-authoritative.
- [ ] Migration is reversible or includes rollback notes.

