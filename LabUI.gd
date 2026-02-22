extends Control

const GACHA_COST := 100

# UI 노드 참조
@onready var log_label = $RootMargin/Card/VBox/LogLabel
@onready var btn_gacha = $RootMargin/Card/VBox/TabGroup/TabRow/BtnGacha
@onready var btn_close = $BtnClose
@onready var card = $RootMargin/Card
@onready var btn_synthesize = $RootMargin/Card/VBox/TabGroup/TabRow/BtnSynthesize
@onready var btn_decompose = $RootMargin/Card/VBox/TabGroup/TabRow/BtnDecompose
@onready var btn_draw_icon = $RootMargin/Card/VBox/IconRow/IconFrame/BtnDrawIcon
@onready var inventory_scroll = $RootMargin/Card/VBox/InventoryPanel/InventoryVBox/ScrollContainer
@onready var inventory_list = $RootMargin/Card/VBox/InventoryPanel/InventoryVBox/ScrollContainer/VBoxHolder/RowCenter/InventoryList
@onready var stone_label = $RootMargin/Card/VBox/TopRow/StoneBox/StoneRow/StoneLabel
@onready var result_label = $RootMargin/Card/VBox/ResultPanel/LastResultLabel
@onready var icon_row = $RootMargin/Card/VBox/IconRow
@onready var result_panel = $RootMargin/Card/VBox/ResultPanel
@onready var inventory_panel = $RootMargin/Card/VBox/InventoryPanel
@onready var tab_placeholder_label = $RootMargin/Card/VBox/TabPlaceholderLabel

# 선택된 재료 저장소 (amount: int or float, PRD 소수점 6자리)
var selected_ingredients = {}
var current_stone := 0
var current_tab := "gacha"
var material_amounts: Dictionary = {}
var is_dragging_window := false
var drag_offset := Vector2i.ZERO

func _format_amount(val) -> String:
	"""PRD: 소수점 이하 6자리까지 표시. 정수는 정수로, 소수는 불필요한 0 제거."""
	var v = float(val)
	if v >= 1000 or (v >= 1 and abs(v - floor(v)) < 1e-9):
		return str(int(round(v)))
	var s = "%.6f" % v
	while s.length() > 1 and s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	if s.ends_with("."):
		s = s.substr(0, s.length() - 1)
	return s

func _ready():
	_fit_to_viewport()
	if not get_viewport().size_changed.is_connected(_fit_to_viewport):
		get_viewport().size_changed.connect(_fit_to_viewport)

	# 버튼 연결
	btn_gacha.pressed.connect(_on_tab_gacha_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	btn_draw_icon.pressed.connect(_on_gacha_pressed)
	
	if btn_synthesize:
		btn_synthesize.pressed.connect(_on_tab_synthesize_pressed)
	if btn_decompose:
		btn_decompose.pressed.connect(_on_tab_decompose_pressed)
	
	# 연구소가 보일 때마다 인벤토리 갱신
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_position_close_button")

func _on_visibility_changed():
	if visible:
		await get_tree().process_frame
		_fit_to_viewport()
		log_label.text = "연구소에 오신 것을 환영합니다."
		_update_result_display({})
		selected_ingredients.clear()
		_sync_stone_from_profile()
		_refresh_stone_label()
		_set_tab("gacha")
		refresh_inventory()

func _fit_to_viewport():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_position_close_button()

func _notification(what):
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_position_close_button()

func _on_close_pressed():
	visible = false

func _position_close_button():
	if card == null or btn_close == null:
		return
	var btn_size = btn_close.size
	var card_pos = card.position
	var card_size = card.size
	btn_close.position = card_pos + Vector2(card_size.x - btn_size.x * 0.62, -btn_size.y * 0.38)

func _input(event):
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_window = true
			drag_offset = DisplayServer.mouse_get_position() - get_window().position
		else:
			is_dragging_window = false

func _process(_delta):
	if not visible:
		return
	if is_dragging_window and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_window().position = DisplayServer.mouse_get_position() - drag_offset
	elif is_dragging_window:
		is_dragging_window = false

func _sync_stone_from_profile():
	var minerals = GameManager.my_profile.get("minerals", {})
	if minerals is Dictionary:
		current_stone = int(minerals.get("stone", 0))
	else:
		current_stone = 0

func _refresh_stone_label():
	stone_label.text = str(current_stone)
	btn_draw_icon.disabled = current_stone < GACHA_COST

func _set_tab(tab_name: String):
	current_tab = tab_name
	var is_gacha = tab_name == "gacha"
	icon_row.visible = is_gacha
	result_panel.visible = is_gacha
	inventory_panel.visible = is_gacha
	tab_placeholder_label.visible = not is_gacha

	if tab_name == "synthesize":
		tab_placeholder_label.text = "돌 합성 탭 준비 중"
	elif tab_name == "decompose":
		tab_placeholder_label.text = "돌 분해 탭 준비 중"
	else:
		tab_placeholder_label.text = ""

func _on_tab_gacha_pressed():
	_set_tab("gacha")

func _on_tab_synthesize_pressed():
	_set_tab("synthesize")

func _on_tab_decompose_pressed():
	_set_tab("decompose")

# ==========================================================
# [수정된 부분] 인벤토리 불러오기 (함수 인자 오류 해결)
# ==========================================================
func refresh_inventory():
	print("[DEBUG] 인벤토리 갱신 요청 시작...")
	
	material_amounts.clear()
		
	var http = HTTPRequest.new()
	add_child(http)
	
	# [수정] _n 인자를 제거하고, http 변수를 직접 큐프리 하도록 변경
	http.request_completed.connect(func(_r, code, _h, body):
		http.queue_free() # 여기서 직접 삭제
		
		var response_str = body.get_string_from_utf8()
		print("[DEBUG] 인벤토리 응답 코드: ", code)
		print("[DEBUG] 인벤토리 응답 데이터: ", response_str) 
		
		if code != 200:
			log_label.text = "인벤토리 불러오기 실패: " + str(code)
			return

		var json = JSON.parse_string(response_str)
		
		if json is Array:
			if json.size() == 0:
				log_label.text = "보유한 원소가 없습니다."
				print("[DEBUG] 데이터가 비어있음 (Empty Array)")
			else:
				print("[DEBUG] 주기율표 데이터 반영 시작: ", json.size(), "개 항목")
				for item in json:
					var symbol = str(item.get("element", ""))
					var amount = item.get("amount", 0)
					if symbol != "":
						material_amounts[symbol] = float(amount) if amount != null else 0.0
		else:
			print("[ERROR] 데이터 형식이 배열이 아닙니다: ", json)
		_rebuild_periodic_table()
		call_deferred("_center_periodic_table")
	)
	
	# 보유량이 0보다 큰 재료만 요청
	var api_url = Auth.URL + "/rest/v1/user_materials?user_id=eq." + Auth.user_id + "&amount=gt.0"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + Auth.KEY, 
		"Authorization: Bearer " + Auth.access_token
	]
	http.request(api_url, headers, HTTPClient.METHOD_GET)

func _rebuild_periodic_table():
	for child in inventory_list.get_children():
		child.queue_free()

	for r in range(1, 11):
		for c in range(1, 19):
			var data = MineralDatabase.get_element_by_coord(r, c)
			if data:
				var sym = str(data.symbol)
				var amt = float(material_amounts.get(sym, 0))
				var in_recipe = MineralDatabase.is_element_valid(sym)
				_add_periodic_cell(sym, amt, in_recipe)
			else:
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(76, 76)
				inventory_list.add_child(spacer)

func _add_periodic_cell(symbol: String, amount: float, in_recipe: bool = true):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(76, 76)

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.12, 0.12, 0.12, 1)
	# 레시피에 없는 원소: 흐리게 | 레시피 있음+미보유: 연하게 | 레시피 있음+보유: 강조
	if not in_recipe:
		style.bg_color = Color(0.88, 0.88, 0.88, 1)
	elif amount > 1e-9:
		style.bg_color = Color(0.72, 0.88, 0.77, 1)
	else:
		style.bg_color = Color(0.90, 0.92, 0.90, 1)
	panel.add_theme_stylebox_override("panel", style)

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var text_color = Color(0.08, 0.08, 0.08, 1) if in_recipe else Color(0.5, 0.5, 0.5, 0.6)
	var amt_color = Color(0.2, 0.2, 0.2, 1) if in_recipe else Color(0.5, 0.5, 0.5, 0.6)
	var symbol_label = Label.new()
	symbol_label.text = symbol
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol_label.add_theme_font_size_override("font_size", 20)
	symbol_label.add_theme_color_override("font_color", text_color)
	var _font_bold = load("res://assets/fonts/IM_Hyemin-Bold.otf") as Font
	if _font_bold:
		symbol_label.add_theme_font_override("font", _font_bold)

	var amount_label = Label.new()
	amount_label.text = _format_amount(amount)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.add_theme_font_size_override("font_size", 16)
	amount_label.add_theme_color_override("font_color", amt_color)

	vbox.add_child(symbol_label)
	vbox.add_child(amount_label)
	center.add_child(vbox)
	panel.add_child(center)
	inventory_list.add_child(panel)

func _center_periodic_table():
	if inventory_scroll == null:
		return
	# 레이아웃 적용 타이밍 이슈를 피하기 위해 2프레임 뒤 최소폭 기준으로 계산
	await get_tree().process_frame
	await get_tree().process_frame
	var content_w: float = maxf(inventory_list.custom_minimum_size.x, inventory_list.get_combined_minimum_size().x)
	var viewport_w: float = inventory_scroll.size.x
	var max_h: float = maxf(0.0, content_w - viewport_w)
	if max_h > 0.0:
		inventory_scroll.scroll_horizontal = int(max_h * 0.5)
	else:
		inventory_scroll.scroll_horizontal = 0
	inventory_scroll.scroll_vertical = 0

# ==========================================================
# 획득 결과 표시 (PRD: 광물명 노출 금지, 원소만 강조)
# ==========================================================
func _update_result_display(elements: Dictionary, show_failure := false):
	# 기존 칩 컨테이너 제거
	for c in result_panel.get_children():
		if c != result_label:
			c.queue_free()
	result_label.visible = true

	if show_failure:
		result_label.text = "최근 결과: 뽑기 실패"
		return
	if elements.is_empty():
		result_label.text = "최근 뽑기 결과가 여기에 표시됩니다."
		return

	# 획득 원소 칩으로 강조 (테마: 광물/과학 느낌)
	result_label.visible = false
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var syms = elements.keys()
	syms.sort()
	for sym in syms:
		var amt = float(elements[sym]) if elements[sym] != null else 0.0
		var chip = _make_element_chip(str(sym), amt)
		hbox.add_child(chip)
	result_panel.add_child(hbox)

func _make_element_chip(symbol: String, amount: float) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 64)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # HBox가 늘어나도 칩은 정사각형 유지
	var style = StyleBoxFlat.new()
	style.set_content_margin_all(8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.bg_color = Color(0.94, 0.97, 0.94, 1)  # 연한 민트/화이트
	style.border_color = Color(0.56, 0.72, 0.60, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var center = CenterContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var sym_label = Label.new()
	sym_label.text = symbol
	sym_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sym_label.add_theme_font_size_override("font_size", 24)
	sym_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.22, 1))
	var _font_bold = load("res://assets/fonts/IM_Hyemin-Bold.otf") as Font
	if _font_bold:
		sym_label.add_theme_font_override("font", _font_bold)

	var amt_label = Label.new()
	amt_label.text = "×" + _format_amount(amount)
	amt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amt_label.add_theme_font_size_override("font_size", 15)
	amt_label.add_theme_color_override("font_color", Color(0.35, 0.50, 0.40, 1))
	if _font_bold:
		amt_label.add_theme_font_override("font", _font_bold)

	vbox.add_child(sym_label)
	vbox.add_child(amt_label)
	center.add_child(vbox)
	panel.add_child(center)
	return panel

# ==========================================================
# Gacha (뽑기)
# ==========================================================
func _on_gacha_pressed():
	btn_draw_icon.disabled = true
	log_label.text = "원소 추출 중..."
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_gacha_completed.bind(http))
	
	var api_url = Auth.URL + "/rest/v1/rpc/purchase_element_pack"
	var headers = ["Content-Type: application/json", "apikey: " + Auth.KEY, "Authorization: Bearer " + Auth.access_token]
	
	http.request(api_url, headers, HTTPClient.METHOD_POST, "{}")

func _on_gacha_completed(_result, response_code, _headers, body, http_node):
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	print("Gacha Result: ", json)

	if response_code == 200 and json.get("status") == "success":
		var stone_bal = int(json.get("current_stone", max(0, current_stone - GACHA_COST)))
		current_stone = stone_bal
		var minerals = GameManager.my_profile.get("minerals", {})
		if not (minerals is Dictionary):
			minerals = {}
		minerals["stone"] = current_stone
		GameManager.my_profile["minerals"] = minerals
		_refresh_stone_label()

		var elements = json.get("elements", {})
		# PRD: "그 돌이 어떤 돌인지는 모르는" → 광물명 표시 금지
		log_label.text = "획득 완료 (Stone: %d)" % current_stone
		_update_result_display(elements)
		refresh_inventory()
	else:
		_refresh_stone_label()
		log_label.text = "실패: " + str(json.get("message", "Unknown"))
		_update_result_display({}, true)