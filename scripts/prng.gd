# res://scripts/prng.gd
class_name PRNG
## 결정적 PRNG (LCG). 0 state 고정/무한루프 방지

var _state: int = 1

func _init(seed_value: int = 1) -> void:
	seed(seed_value)

func seed(s: int) -> void:
	_state = int(s) & 0x7fffffff
	if _state == 0:
		_state = 1

func _next_u32() -> int:
	# LCG: Numerical Recipes 계열
	_state = int((_state * 1664525 + 1013904223) & 0x7fffffff)
	if _state == 0:
		_state = 1
	return _state

func randf() -> float:
	return float(_next_u32()) / 2147483648.0  # [0,1)

func rand_range(a: float, b: float) -> float:
	return a + randf() * (b - a)

func randi_range(a: int, b: int) -> int:
	if a >= b:
		return a
	return a + int(randf() * float(b - a + 1))
