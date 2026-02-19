---
name: procedural-stone-spec
description: Defines canonical stone definition data for procedural regeneration, versioning, and compatibility. Use when implementing or reviewing stone generation, seed/DNA schema, recipe fields, stone serialization, or re-render logic from saved data.
---

# Procedural Stone Spec

## Use This Skill When

- User asks about `돌 정의 데이터`, `seed`, `DNA`, `레시피`, `미량 원소`.
- Implementing stone save/load, migration, or re-render from DB.
- Reviewing whether a feature stores images instead of canonical data.

## Core Rules

1. Treat procedural definition as source of truth; rendered image is derived output.
2. Persist canonical fields only (no screenshot/image blob as primary data).
3. Always include a schema version for forward/backward compatibility.
4. Regenerate visual output from stored definition on every display surface.

## Canonical Data Contract

Use this minimum shape (names can vary by codebase convention):

```json
{
  "schema_version": 1,
  "stone_id": "uuid",
  "seed": "int-or-string",
  "dna": {},
  "recipe": {},
  "trace_elements": [],
  "created_at": "iso-8601",
  "created_by": "user-id"
}
```

Notes:
- `schema_version` is mandatory.
- `seed` + `dna` + `recipe` should deterministically reproduce appearance/stats.
- Keep denormalized display fields optional and recomputable.

## Implementation Workflow

1. Identify all write paths that create or mutate stones.
2. Validate they persist canonical definition fields and version.
3. Identify all read/display paths (widget, list, detail, ranking).
4. Ensure each display path reconstructs from canonical data.
5. Add compatibility handling for older schema versions.

## Review Checklist

- [ ] No path relies on stored screenshots as authoritative data.
- [ ] Canonical fields are sufficient for deterministic regeneration.
- [ ] Schema version exists and is validated.
- [ ] Missing/legacy fields have safe fallback logic.
- [ ] Logs/errors include stone id and schema version for debugging.

