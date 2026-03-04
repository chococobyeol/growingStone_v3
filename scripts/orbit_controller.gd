extends Node3D
## Orbit 컨트롤: 마우스 드래그 회전, 휠 줌
## UI 위에서 드래그할 때 카메라가 같이 도는 문제를 방지한다.

@export var target_path: NodePath
@export var orbit_speed: float = 0.003
@export var zoom_speed: float = 0.5
@export var min_distance: float = 1.0
@export var max_distance: float = 20.0

var _distance: float = 6.0
var _yaw: float = 0.0
var _pitch: float = 0.4

var target: Node3D

func _ready() -> void:
	if target_path:
		target = get_node_or_null(target_path)
	if not target:
		target = get_parent()
	_update_position()

func _unhandled_input(event: InputEvent) -> void:
	# GUI가 마우스를 사용 중이면 오비트 컨트롤러는 무시
	if _is_pointer_over_ui():
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = clampf(_distance - zoom_speed, min_distance, max_distance)
			_update_position()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = clampf(_distance + zoom_speed, min_distance, max_distance)
			_update_position()

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_yaw -= mm.relative.x * orbit_speed
			_pitch = clampf(_pitch - mm.relative.y * orbit_speed, -1.4, 1.4)
			_update_position()

func _update_position() -> void:
	var t := target.global_position if target else Vector3.ZERO
	global_position = t + Vector3(
		cos(_pitch) * sin(_yaw),
		sin(_pitch),
		cos(_pitch) * cos(_yaw)
	) * _distance

	var cam := get_node_or_null("Camera3D") as Camera3D
	if cam and target:
		cam.look_at(t)

func set_distance(d: float) -> void:
	_distance = clampf(d, min_distance, max_distance)
	_update_position()

func _is_pointer_over_ui() -> bool:
	# Godot 4: 현재 마우스 아래의 Control을 얻는다.
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null
