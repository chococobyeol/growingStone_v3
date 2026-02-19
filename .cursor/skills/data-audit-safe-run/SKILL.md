---
name: data-audit-safe-run
description: Safely executes and reviews data_audit scripts with environment hygiene and verification steps. Use when running upload/import/audit scripts, validating Supabase writes, or preparing rollback and dry-run checks.
---

# Data Audit Safe Run

## Use This Skill When

- User asks to run or modify scripts under `data_audit/`.
- Work touches `.env`, upload scripts, or production-like data writes.
- Need safe execution and verification plan before DB changes.

## Safety Baseline

1. Never print secrets from `.env` in logs or responses.
2. Prefer dry-run mode first; if missing, add read-only preview step.
3. Validate target environment (dev/staging/prod) explicitly before write.
4. Keep rollback/retry plan before executing bulk operations.

## Execution Workflow

1. Confirm script purpose and affected tables/rows.
2. Check required env keys exist (without exposing values).
3. Run preflight validation query or sample check.
4. Execute in small batch first, inspect results.
5. Continue full run only if sample batch is correct.
6. Run post-check: counts, duplicates, null-critical fields, constraints.

## Verification Template

Use concise record after execution:

```markdown
- target: staging
- script: upload_v15_to_supabase.py
- precheck: expected 120 rows, 0 conflicts
- sample run: 20 rows inserted, schema valid
- full run: 120/120 success
- postcheck: no duplicate keys, required columns non-null
```

## Review Checklist

- [ ] Secret values were never exposed.
- [ ] Target environment and table scope were verified.
- [ ] Dry-run or sample batch was validated first.
- [ ] Post-run integrity checks passed.
- [ ] Rollback path is documented when partial failure occurs.

