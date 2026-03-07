extends Node3D
# test_poly_crystal.gd

@onready var cluster: Node3D = $Cluster
@onready var mesh_label: Label = $CanvasLayer/UI/VBox/StatsLabel

@onready var seed_spin: SpinBox = $CanvasLayer/UI/VBox/H1/SeedBox
@onready var f_slider: HSlider = $CanvasLayer/UI/VBox/H2/FSlider
@onready var c_slider: HSlider = $CanvasLayer/UI/VBox/H3/CSlider
@onready var k_slider: HSlider = $CanvasLayer/UI/VBox/H4/KSlider
@onready var a_slider: HSlider = $CanvasLayer/UI/VBox/H5/ASlider

@onready var sides_spin: SpinBox = $CanvasLayer/UI/VBox/H6/SidesBox
@onready var height_slider: HSlider = $CanvasLayer/UI/VBox/H7/HeightSlider
@onready var rtop_slider: HSlider = $CanvasLayer/UI/VBox/H8/RadiusTopSlider
@onready var rbot_slider: HSlider = $CanvasLayer/UI/VBox/H9/RadiusBottomSlider
@onready var term_slider: HSlider = $CanvasLayer/UI/VBox/H10/TerminationSlider

@onready var ortho_check: CheckBox = $CanvasLayer/UI/VBox/H11/OrthoCheck
@onready var fov_slider: HSlider = $CanvasLayer/UI/VBox/H12/FovSlider

var _poly: Object
var _PolyClass: Script

func _ready() -> void:
	print("[TEST_POLY] _ready() scene=", get_tree().current_scene)

	_PolyClass = load("res://scripts/poly_crystal_generator.gd")
	if _PolyClass == null:
		push_error("[TEST_POLY] FAILED to load poly_crystal_generator.gd (null). 경로 확인.")
		_spawn_debug_cube()
		return

	_poly = _PolyClass.new()
	if _poly == null:
		push_error("[TEST_POLY] FAILED to instantiate PolyCrystalGenerator. (new() null)")
		_spawn_debug_cube()
		return

	print("[TEST_POLY] poly instance ok: ", _poly)

	_connect_controls()
	_apply_camera_mode()

	call_deferred("_rebuild")

func _connect_controls() -> void:
	var controls = [
		seed_spin, f_slider, c_slider, k_slider, a_slider,
		sides_spin, height_slider, rtop_slider, rbot_slider, term_slider,
		ortho_check, fov_slider
	]
	for c in controls:
		if c is SpinBox:
			c.value_changed.connect(_on_any_changed)
		elif c is CheckBox:
			c.toggled.connect(_on_any_changed)
		else:
			c.value_changed.connect(_on_any_changed)

func _on_any_changed(_v = null) -> void:
	_apply_camera_mode()
	_rebuild()

func _apply_camera_mode() -> void:
	var cam := $CameraRig/Camera3D as Camera3D
	if cam == null:
		push_error("[TEST_POLY] Camera3D not found at $CameraRig/Camera3D")
		return

	if ortho_check.button_pressed:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 4.0
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = fov_slider.value

func _rebuild() -> void:
	if _poly == null:
		push_error("[TEST_POLY] _poly is null, cannot rebuild.")
		_spawn_debug_cube()
		return

	var p: Dictionary = _poly.call("default_params")
	p["seed"] = int(seed_spin.value)
	p["F"] = f_slider.value
	p["C"] = c_slider.value
	p["K"] = k_slider.value
	p["A"] = a_slider.value

	var s: Dictionary = p["single"]
	s["sides"] = clampi(int(sides_spin.value), 3, 12)
	s["height"] = height_slider.value
	s["radius_top"] = rtop_slider.value
	s["radius_bottom"] = rbot_slider.value
	s["termination"] = term_slider.value
	p["single"] = s

	print("[TEST_POLY] rebuild seed=%d F=%.2f C=%.2f K=%.2f A=%.2f" % [p["seed"], p["F"], p["C"], p["K"], p["A"]])

	print("[TEST_POLY] cluster children(before)=", cluster.get_child_count())
	print("[TEST_POLY] calling build_cluster_into...")
	var result = _poly.call("build_cluster_into", cluster, p)
	print("[TEST_POLY] returned from build_cluster_into")
	print("[TEST_POLY] result=", result)
	print("[TEST_POLY] cluster children(after)=", cluster.get_child_count())

	if cluster.get_child_count() == 0:
		push_warning("[TEST_POLY] cluster is still empty after build. Spawning debug cube.")
		_spawn_debug_cube()

	mesh_label.text = "seed=%d  F=%.2f C=%.2f K=%.2f A=%.2f" % [
		p["seed"], p["F"], p["C"], p["K"], p["A"]
	]

	var orbit := $CameraRig as Node
	if orbit and orbit.has_method("reset_distance"):
		orbit.call("reset_distance", 7.0)

func _spawn_debug_cube() -> void:
	if cluster.get_node_or_null("DebugCube") != null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "DebugCube"
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.2, 0.2, 1)
	mat.roughness = 0.6
	mi.material_override = mat
	cluster.add_child(mi)
	print("[TEST_POLY] DebugCube spawned.")
