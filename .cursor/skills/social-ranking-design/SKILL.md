---
name: social-ranking-design
description: Designs and validates stone sharing, like reactions, and weekly ranking flows without storing screenshots. Use when implementing or reviewing social feed, share metadata, likes, anti-abuse guards, and weekly leaderboard logic.
---

# Social Ranking Design

## Use This Skill When

- User asks for `돌 자랑`, `공유`, `좋아요`, `주간 순위`, `leaderboard`, `feed`.
- Implementing profile text (title/description) attached to shared stones.
- Reviewing ranking fairness, abuse prevention, or reset windows.

## Product Rules

1. Do not store screenshot/image as canonical source.
2. Store stone definition data and regenerate visuals for feed/ranking/detail.
3. Shared item includes user-authored profile text (title, one-liner, description).
4. Ranking is weekly and based on valid reaction counts.

## Data Model Minimum

- `shared_stones`
  - `id`, `user_id`, `stone_definition`, `title`, `summary`, `description`, `created_at`
- `stone_likes`
  - `shared_stone_id`, `user_id`, `created_at`
  - unique: (`shared_stone_id`, `user_id`)
- optional aggregate view/materialized table
  - `week_key`, `shared_stone_id`, `likes_count`, `rank_score`

## Ranking Window

- Define one canonical week boundary (e.g., KST Monday 00:00).
- Compute `week_key` deterministically on server.
- Tie-break order default: `likes_count desc`, then `created_at asc`, then `id asc`.

## Anti-Abuse Defaults

- One account = one like per shared stone.
- Ignore/flag likes from blocked or invalid accounts.
- Rate-limit burst actions at API edge.
- Keep audit logs for moderation and dispute checks.

## Review Checklist

- [ ] Shared stone render path uses stored definition, not cached image source.
- [ ] Profile text fields are validated (length, empty handling, profanity policy if needed).
- [ ] Weekly boundary/timezone is consistent across API and UI.
- [ ] Ranking query has stable deterministic tie-breakers.
- [ ] Reaction uniqueness and abuse guardrails are enforced.

