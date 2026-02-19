---
name: economy-balance-tuning
description: Tunes game economy for stone gain/spend loops using measurable targets and anti-exploit checks. Use when adjusting rewards, costs, progression pacing, sink/source balance, or economy-related telemetry interpretation.
---

# Economy Balance Tuning

## Use This Skill When

- User asks to adjust stone rewards, costs, pacing, or retention feel.
- New systems add a source or sink for currency/materials.
- Need to diagnose inflation, stagnation, or exploit-friendly loops.

## Balancing Principles

1. Define target progression windows before changing numbers.
2. Tune sources and sinks together, not in isolation.
3. Keep early-game clarity, mid-game choices, late-game aspiration.
4. Prevent dominant strategy where one loop strictly outperforms all others.

## Practical Tuning Workflow

1. Set baseline metrics (gain/min, spend/min, median progression step).
2. Simulate or sample current loop outcomes.
3. Adjust one factor group at a time (reward, cost, cooldown, drop table).
4. Re-check edge cases (offline growth, retry loops, chained bonuses).
5. Compare against target and rollback if volatility spikes.

## Anti-Exploit Checks

- Rapid repeat loops that farm net-positive currency.
- Clock/time manipulation affecting offline or weekly calculations.
- Multiplicative stacking that exceeds intended caps.
- Market/arbitrage pattern creating risk-free gains.

## Review Checklist

- [ ] Early progression is not blocked by excessive costs.
- [ ] Mid/late progression does not collapse into inflation.
- [ ] Sources vs sinks are roughly stable for active players.
- [ ] No obvious zero-risk exploit path remains.
- [ ] Changes are tied to measurable before/after observations.

