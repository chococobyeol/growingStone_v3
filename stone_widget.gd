extends Control

## 3D 돌을 SubViewport 안에서 렌더링하고, apply_stone_data를 StoneRoot에 전달합니다.

func _ready() -> void:
	# Node2D 아래에서는 레이아웃이 없어 크기가 0이 됨 → 명시적 크기 지정
	size = Vector2(256, 256)

func apply_stone_data(stone_data: Dictionary) -> void:
	var root = get_node_or_null("SubViewportContainer/SubViewport/StoneRoot")
	if root == null:
		push_error("[StoneWidget] StoneRoot not found (path: SubViewportContainer/SubViewport/StoneRoot)")
		return
	if not root.has_method("apply_stone_data"):
		push_error("[StoneWidget] StoneRoot has no apply_stone_data")
		return
	root.apply_stone_data(stone_data)
	print("[StoneWidget] apply_stone_data forwarded to StoneRoot OK")
