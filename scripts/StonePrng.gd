class_name StonePRNG
extends RefCounted

## SYNTHESIS_DESIGN 10.2·10.3: 엔진 업데이트에 독립적인 고정 LCG.
## 같은 시드 → 같은 수열 → 동일 렌더링.

var state: int = 0

func _init(seed_val: int = 0):
	if seed_val == 0:
		seed_val = randi()
	state = seed_val & 0x7FFFFFFF
	if state == 0:
		state = 1

func rand() -> int:
	state = (state * 1103515245 + 12345) & 0x7FFFFFFF
	return state

func randf() -> float:
	return float(rand()) / 2147483648.0

func randf_range(min_val: float, max_val: float) -> float:
	return min_val + randf() * (max_val - min_val)

func randi_range(min_val: int, max_val: int) -> int:
	if min_val >= max_val:
		return min_val
	return min_val + (rand() % (max_val - min_val + 1))
