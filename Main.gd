extends Node2D

var is_widget_mode = false
var is_dragging = false
var drag_offset = Vector2i.ZERO
@onready var lab_ui = $LabUI # 노드 경로 확인 필수!

@onready var stone = $Stone

func _ready():
		# [추가] 깜빡임 방지: 일단 숨기고 시작
	stone.visible = false 
	
	await get_tree().process_frame
	
	print("[Main] Requesting Game Data...")
	
	# GameManager 신호 연결
	GameManager.data_loaded.connect(_on_data_loaded)
	GameManager.no_stone_found.connect(_on_no_stone_found)
	
	# 데이터 로드 시작
	GameManager.fetch_user_profile()

# [상황 1] 돌이 있을 때 -> 정보 출력
func _on_data_loaded():
	print("============ GAME START ============")
	print("User: ", GameManager.my_profile.get("nickname", "Unknown"))
	
	var stone_data = GameManager.my_stone
	var recipe = stone_data.get("mineral_recipes", {})
	var stone_name = recipe.get("name", "Unknown Mineral")
	
	print("Stone Type: ", stone_name) 
	print("Mass: ", recipe.get("base_density", 0.0), " (density)")
	
	# 여기에 나중에 돌 이미지를 바꾸는 코드가 들어감
	stone.visible = true

# [상황 2] 돌이 없을 때 -> 로그 출력 (추후 UI 띄움)
func _on_no_stone_found():
	print("============ NO STONE ============")
	print("Opening Lab...")
	# 임시로 돌을 숨김
	stone.visible = false
	# [추가] 연구소 UI 열기
	if lab_ui:
		lab_ui.visible = true

# --- 아래는 윈도우 이동/제어 로직 (기존과 동일) ---
func _process(_delta):
	if is_dragging:
		var current_mouse_pos = DisplayServer.mouse_get_position()
		get_window().position = current_mouse_pos - drag_offset
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			is_dragging = false

func _on_stone_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if event.double_click:
					is_dragging = false
					toggle_mode()
				else:
					is_dragging = true
					drag_offset = DisplayServer.mouse_get_position() - get_window().position
			else:
				is_dragging = false

func toggle_mode():
	is_widget_mode = !is_widget_mode
	if is_widget_mode: apply_widget_mode()
	else: apply_window_mode()

func apply_widget_mode():
	var window = get_window()
	window.size = Vector2i(1000, 700)
	window.transparent_bg = true
	window.transparent = true
	window.borderless = true
	window.always_on_top = true
	window.unresizable = true

func apply_window_mode():
	var window = get_window()
	window.size = Vector2i(1600, 1000)
	window.borderless = false
	window.transparent = false
	window.transparent_bg = false
	window.always_on_top = false
	window.unresizable = false
	window.move_to_center()


	# Main.gd



