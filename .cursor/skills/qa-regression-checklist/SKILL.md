---
name: qa-regression-checklist
description: Runs a lightweight regression checklist for core gameplay loops and backend sync. Use when validating feature changes across login, synthesis/decomposition, widget idle growth, auction, collection, and social sharing flows.
---

# QA Regression Checklist

## Use This Skill When

- User asks to verify changes before merge/release.
- Core loop or backend sync logic changed.
- Need quick confidence on cross-feature regressions.

## Smoke Test Matrix

Run only relevant rows for the current change:

- Login/session restore
- Stone 지급/원소 뽑기
- 합성/분해 결과 및 로그 반영
- 위젯 방치 성장(재접속 보정)
- 경매 등록/입찰/정산 (해당 Phase에서)
- 도감 반영/업적 카운트
- 돌 자랑 공유/좋아요/주간 순위 (해당 Phase에서)

## Validation Method

1. Validate happy path once end-to-end.
2. Validate one failure path per touched feature.
3. Confirm persisted state in Supabase is consistent.
4. Re-enter app/session and confirm state restoration.

## Release Gate

Mark pass/fail with one-line evidence per test:

```markdown
- [pass] synthesis happy path: stone created and log entry persisted
- [pass] share like uniqueness: duplicate like blocked by unique constraint
- [fail] weekly rank boundary: timezone mismatch (KST vs UTC)
```

## Review Checklist

- [ ] Changed features have both happy/failure path checks.
- [ ] No auth or cross-user data leakage observed.
- [ ] DB state matches in-game state after reconnect.
- [ ] Time-bound features (auction/ranking) validated with server time assumption.

