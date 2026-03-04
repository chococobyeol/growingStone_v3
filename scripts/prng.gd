##prng.gd
class_name PRNG
## 결정적 PRNG. seed 고정 시 동일 결과 보장.
## Godot 내장 RNG 대신 사용해 엔진 변경 시에도 재현성을 유지.

var _state: int = 0

func _init(seed_value: int = 0) -> void:
	seed(seed_value)

func seed(s: int) -> void:
	_state = s if s != 0 else 1

## [0, 1) 균등 분포 float
func randf() -> float:
	_state ^= _state << 13
	_state ^= _state >> 17
	_state ^= _state << 5
	_state &= 0x7FFFFFFF
	return float(_state) / 2147483648.0

## [a, b) 범위 float
func rand_range(a: float, b: float) -> float:
	return a + randf() * (b - a)

## [a, b] 범위 int (양 끝 포함)
func randi_range(a: int, b: int) -> int:
	if a >= b:
		return a
	return a + int(randf() * (b - a + 1))
