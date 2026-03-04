#test_crystal.gd
extends Node3D
## 단결정 테스트 씬: 파라미터 조절 UI + 즉시 재생성

@onready var mesh_instance: MeshInstance3D = $Crystal/MeshInstance3D
@onready var seed_spin: SpinBox = $CanvasLayer/UI/VBox/H1/SeedBox
@onready var sides_spin: SpinBox = $CanvasLayer/UI/VBox/H2/SidesBox
@onready var height_slider: HSlider = $CanvasLayer/UI/VBox/H3/HeightSlider
@onready var radius_top_slider: HSlider = $CanvasLayer/UI/VBox/H4/RadiusTopSlider
@onready var radius_bottom_slider: HSlider = $CanvasLayer/UI/VBox/H5/RadiusBottomSlider
@onready var termination_slider: HSlider = $CanvasLayer/UI/VBox/H6/TerminationSlider
@onready var chip_slider: HSlider = $CanvasLayer/UI/VBox/H7/ChipSlider
@onready var etch_slider: HSlider = $CanvasLayer/UI/VBox/H8/EtchSlider
var _gen
var _CrystalClass: GDScript

func _ready() -> void:
	_CrystalClass = load("res://scripts/crystal_generator.gd") as GDScript
	_gen = _CrystalClass.new()
	var cam := $CameraRig/Camera3D as Camera3D
	if cam:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 3.5
	_connect_controls()
	_rebuild_crystal()

func _connect_controls() -> void:
	var controls = [seed_spin, sides_spin, height_slider, radius_top_slider, radius_bottom_slider,
		termination_slider, chip_slider, etch_slider]
	for c in controls:
		if c is SpinBox:
			c.value_changed.connect(_on_value_changed)
		else:
			c.value_changed.connect(_on_value_changed)

func _on_value_changed(_v = null) -> void:
	_rebuild_crystal()

func _rebuild_crystal() -> void:
	var params = _gen.default_params()
	params["seed"] = int(seed_spin.value)
	params["sides"] = clampi(int(sides_spin.value), 3, 12)
	params["height"] = height_slider.value
	params["radius_top"] = radius_top_slider.value
	params["radius_bottom"] = radius_bottom_slider.value
	params["termination"] = termination_slider.value
	params["termination_height"] = 0.6  # 비율값 (height 곱하지 않음)
	params["cap_bottom"] = true
	params["chip"] = chip_slider.value
	params["etch"] = etch_slider.value
	mesh_instance.mesh = _gen.build_single_crystal(params)
