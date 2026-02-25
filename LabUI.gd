extends Control

const GACHA_COST := 100
const SYNTHESIS_COST_PER_BATCH := 50
const TRACE_ELEMENTS := ["Cr", "Fe", "Ti", "Mn", "Cu", "Co", "V", "Ni"]
const PERIODIC_CELL_SIZE_GACHA := 76

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
@onready var root_vbox = $RootMargin/Card/VBox
@onready var draw_label = $RootMargin/Card/VBox/IconRow/IconFrame/BtnDrawIcon/DrawContent/DrawLabel

# 선택된 재료 저장소
var selected_ingredients: Dictionary = {} # symbol -> available amount
var selected_ratios: Dictionary = {}      # symbol -> integer ratio
var selected_order: Array[String] = []    # 클릭(선택) 순서 유지
var trace_entries: Array = []             # [{element, amount_level}]

var current_stone := 0
var current_tab := "gacha"
var material_amounts: Dictionary = {}
var periodic_cell_panels: Dictionary = {}
var is_dragging_window := false
var drag_offset := Vector2i.ZERO

var synth_root: HBoxContainer
var selected_rows: VBoxContainer
var selected_empty_label: Label
var selected_summary_label: Label
var temperature_buttons: Array[Button] = []
var selected_temperature := 3
var pressure_low_btn: Button
var pressure_high_btn: Button
var selected_pressure := "low"
var trace_list_label: Label
var trace_hint_label: Label
var trace_chip_row: HBoxContainer
var trace_picker_popup: PopupPanel
var trace_popup_element_option: OptionButton
var trace_popup_amount_option: OptionButton
var btn_add_trace: Button
var btn_synthesize_exec: Button
var synth_toggle_row: HBoxContainer
var synth_toggle_btn: Button
var synth_left_panel: PanelContainer
var synth_right_panel: PanelContainer
var is_synth_controls_collapsed := true

func _log_debug(scope: String, message: String, data = null):
	if data == null:
		print("[LabUI][%s] %s" % [scope, message])
	else:
		print("[LabUI][%s] %s | %s" % [scope, message, JSON.stringify(data)])

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
	_build_synthesis_panel()
	call_deferred("_position_close_button")

func _on_visibility_changed():
	if visible:
		await get_tree().process_frame
		_fit_to_viewport()
		log_label.text = "연구소에 오신 것을 환영합니다."
		_update_result_display({})
		selected_ingredients.clear()
		selected_ratios.clear()
		selected_order.clear()
		trace_entries.clear()
		selected_temperature = 3
		selected_pressure = "low"
		_rebuild_selected_list()
		_refresh_trace_list_label()
		_update_temperature_segment_ui()
		_update_pressure_toggle_ui()
		_sync_stone_from_profile()
		_refresh_stone_label()
		_set_tab("gacha")
		refresh_inventory()

func _fit_to_viewport():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_position_close_button()
	if current_tab == "synthesize":
		_update_synth_layout()

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
	_refresh_action_button_state()

func _refresh_action_button_state():
	if current_tab == "gacha":
		btn_draw_icon.visible = true
		btn_draw_icon.disabled = current_stone < GACHA_COST
		if btn_synthesize_exec:
			btn_synthesize_exec.visible = false
	elif current_tab == "synthesize":
		btn_draw_icon.visible = false
		if btn_synthesize_exec:
			btn_synthesize_exec.visible = true
			btn_synthesize_exec.disabled = selected_ingredients.is_empty()
	else:
		btn_draw_icon.visible = false
		btn_draw_icon.disabled = true
		if btn_synthesize_exec:
			btn_synthesize_exec.visible = false

func _make_tab_style(bg: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left = 8
	return s

func _apply_tab_visuals():
	var inactive_bg = Color(1, 1, 1, 1)
	var inactive_text = Color(0.08, 0.08, 0.08, 1)
	var gacha_active_bg = Color(0.67, 0.85, 0.73, 1)
	var synth_active_bg = Color(0.43, 0.63, 0.92, 1)
	var decompose_active_bg = Color(0.90, 0.66, 0.40, 1)
	var active_text = Color(1, 1, 1, 1)

	btn_gacha.add_theme_stylebox_override("normal", _make_tab_style(gacha_active_bg if current_tab == "gacha" else inactive_bg))
	btn_synthesize.add_theme_stylebox_override("normal", _make_tab_style(synth_active_bg if current_tab == "synthesize" else inactive_bg))
	btn_decompose.add_theme_stylebox_override("normal", _make_tab_style(decompose_active_bg if current_tab == "decompose" else inactive_bg))

	btn_gacha.add_theme_color_override("font_color", active_text if current_tab == "gacha" else inactive_text)
	btn_synthesize.add_theme_color_override("font_color", active_text if current_tab == "synthesize" else inactive_text)
	btn_decompose.add_theme_color_override("font_color", active_text if current_tab == "decompose" else inactive_text)

func _update_synth_toggle_ui():
	if synth_toggle_btn == null:
		return
	if is_synth_controls_collapsed:
		synth_toggle_btn.text = "▼ 선택 원소/조건 보기"
	else:
		synth_toggle_btn.text = "▲ 주기율표로 돌아가기"
	_update_synth_layout()

func _on_synth_toggle_pressed():
	is_synth_controls_collapsed = not is_synth_controls_collapsed
	_update_synth_toggle_ui()

func _build_synthesis_panel():
	synth_toggle_row = HBoxContainer.new()
	synth_toggle_row.custom_minimum_size = Vector2(0, 42)
	synth_toggle_row.visible = false
	synth_toggle_btn = Button.new()
	synth_toggle_btn.custom_minimum_size = Vector2(220, 36)
	synth_toggle_btn.pressed.connect(_on_synth_toggle_pressed)
	synth_toggle_btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	synth_toggle_row.add_child(synth_toggle_btn)

	synth_root = HBoxContainer.new()
	synth_root.custom_minimum_size = Vector2(0, 126)
	synth_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synth_root.add_theme_constant_override("separation", 12)
	synth_root.visible = false

	synth_left_panel = PanelContainer.new()
	synth_left_panel.custom_minimum_size = Vector2(560, 126)
	synth_left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	synth_left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synth_left_panel.size_flags_stretch_ratio = 1.35
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(1, 1, 1, 1)
	left_style.border_color = Color(0.72, 0.72, 0.72, 1)
	left_style.border_width_left = 1
	left_style.border_width_top = 1
	left_style.border_width_right = 1
	left_style.border_width_bottom = 1
	left_style.corner_radius_top_left = 8
	left_style.corner_radius_top_right = 8
	left_style.corner_radius_bottom_right = 8
	left_style.corner_radius_bottom_left = 8
	synth_left_panel.add_theme_stylebox_override("panel", left_style)

	var left_vbox = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 6)
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synth_left_panel.add_child(left_vbox)

	var selected_title = Label.new()
	selected_title.text = "선택 원소 리스트 / 정수 비율"
	selected_title.add_theme_font_size_override("font_size", 20)
	selected_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	left_vbox.add_child(selected_title)

	var selected_scroll = ScrollContainer.new()
	selected_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(selected_scroll)

	selected_rows = VBoxContainer.new()
	selected_rows.add_theme_constant_override("separation", 4)
	selected_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_scroll.add_child(selected_rows)

	selected_empty_label = Label.new()
	selected_empty_label.text = "주기율표에서 원소를 선택하세요."
	selected_empty_label.add_theme_font_size_override("font_size", 18)
	selected_empty_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	selected_rows.add_child(selected_empty_label)

	selected_summary_label = Label.new()
	selected_summary_label.text = "1회분 소모 총량: 0 / 300"
	selected_summary_label.add_theme_font_size_override("font_size", 16)
	selected_summary_label.add_theme_color_override("font_color", Color(0.25, 0.25, 0.25, 1))
	left_vbox.add_child(selected_summary_label)

	synth_right_panel = PanelContainer.new()
	synth_right_panel.custom_minimum_size = Vector2(420, 126)
	synth_right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	synth_right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synth_right_panel.size_flags_stretch_ratio = 1.0
	var right_style = left_style.duplicate()
	synth_right_panel.add_theme_stylebox_override("panel", right_style)
	var right_center = CenterContainer.new()
	right_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	synth_right_panel.add_child(right_center)
	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 14)
	right_center.add_child(right_vbox)

	var env_box = PanelContainer.new()
	env_box.custom_minimum_size = Vector2(300, 56)
	var env_style = StyleBoxFlat.new()
	env_style.bg_color = Color(1, 1, 1, 1)
	env_style.border_color = Color(0.12, 0.12, 0.12, 1)
	env_style.border_width_left = 1
	env_style.border_width_top = 1
	env_style.border_width_right = 1
	env_style.border_width_bottom = 1
	env_style.corner_radius_top_left = 6
	env_style.corner_radius_top_right = 6
	env_style.corner_radius_bottom_right = 6
	env_style.corner_radius_bottom_left = 6
	env_box.add_theme_stylebox_override("panel", env_style)
	var env_vbox = VBoxContainer.new()
	env_vbox.add_theme_constant_override("separation", 4)
	env_box.add_child(env_vbox)
	var temp_label = Label.new()
	temp_label.text = "온도"
	temp_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	var temp_row = HBoxContainer.new()
	temp_row.add_theme_constant_override("separation", 4)
	temp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var temp_group = ButtonGroup.new()
	temperature_buttons.clear()
	for i in range(1, 6):
		var b = Button.new()
		b.toggle_mode = true
		b.button_group = temp_group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 30)
		if i == 1:
			b.text = "1(급냉)"
		elif i == 5:
			b.text = "5(서냉)"
		else:
			b.text = str(i)
		b.toggled.connect(_on_temperature_segment_toggled.bind(i))
		temperature_buttons.append(b)
		temp_row.add_child(b)
	env_vbox.add_child(temp_label)
	env_vbox.add_child(temp_row)
	_update_temperature_segment_ui()
	right_vbox.add_child(env_box)

	var pressure_box = PanelContainer.new()
	pressure_box.custom_minimum_size = Vector2(300, 56)
	pressure_box.add_theme_stylebox_override("panel", env_style.duplicate())
	var pressure_vbox = VBoxContainer.new()
	pressure_vbox.add_theme_constant_override("separation", 4)
	pressure_box.add_child(pressure_vbox)
	var pressure_row = HBoxContainer.new()
	pressure_row.add_theme_constant_override("separation", 8)
	pressure_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var pressure_label = Label.new()
	pressure_label.text = "압력"
	pressure_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	var pressure_group = ButtonGroup.new()
	pressure_low_btn = Button.new()
	pressure_low_btn.text = "저압"
	pressure_low_btn.toggle_mode = true
	pressure_low_btn.button_group = pressure_group
	pressure_low_btn.custom_minimum_size = Vector2(130, 34)
	pressure_low_btn.toggled.connect(_on_pressure_toggled.bind("low"))
	pressure_high_btn = Button.new()
	pressure_high_btn.text = "고압"
	pressure_high_btn.toggle_mode = true
	pressure_high_btn.button_group = pressure_group
	pressure_high_btn.custom_minimum_size = Vector2(130, 34)
	pressure_high_btn.toggled.connect(_on_pressure_toggled.bind("high"))
	pressure_row.add_child(pressure_low_btn)
	pressure_row.add_child(pressure_high_btn)
	pressure_vbox.add_child(pressure_label)
	pressure_vbox.add_child(pressure_row)
	_update_pressure_toggle_ui()
	right_vbox.add_child(pressure_box)

	var trace_box = PanelContainer.new()
	trace_box.custom_minimum_size = Vector2(300, 96)
	trace_box.add_theme_stylebox_override("panel", env_style.duplicate())
	var trace_vbox = VBoxContainer.new()
	trace_vbox.add_theme_constant_override("separation", 6)
	trace_box.add_child(trace_vbox)
	btn_add_trace = Button.new()
	btn_add_trace.text = "미량원소 첨가"
	btn_add_trace.custom_minimum_size = Vector2(280, 32)
	btn_add_trace.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	btn_add_trace.pressed.connect(_on_add_trace_pressed)
	trace_chip_row = HBoxContainer.new()
	trace_chip_row.add_theme_constant_override("separation", 6)
	trace_chip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	trace_vbox.add_child(btn_add_trace)
	trace_vbox.add_child(trace_chip_row)
	right_vbox.add_child(trace_box)

	trace_list_label = Label.new()
	trace_list_label.text = "미량원소 첨가: 없음"
	trace_list_label.add_theme_font_size_override("font_size", 14)
	trace_list_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	trace_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var synth_btn_center = CenterContainer.new()
	synth_btn_center.custom_minimum_size = Vector2(300, 88)
	btn_synthesize_exec = Button.new()
	btn_synthesize_exec.text = "합성"
	btn_synthesize_exec.custom_minimum_size = Vector2(120, 80)
	btn_synthesize_exec.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	btn_synthesize_exec.pressed.connect(_on_synthesize_pressed)
	synth_btn_center.add_child(btn_synthesize_exec)
	right_vbox.add_child(synth_btn_center)

	trace_hint_label = Label.new()
	trace_hint_label.text = "미량원소 추가 선택(필수 아님)"
	trace_hint_label.add_theme_font_size_override("font_size", 16)
	trace_hint_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	trace_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	trace_list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	right_vbox.add_child(trace_hint_label)
	right_vbox.add_child(trace_list_label)
	_build_trace_picker_popup()
	_refresh_trace_list_label()

	synth_root.add_child(synth_left_panel)
	synth_root.add_child(synth_right_panel)

	root_vbox.add_child(synth_toggle_row)
	root_vbox.add_child(synth_root)
	root_vbox.move_child(synth_toggle_row, inventory_panel.get_index() + 1)
	root_vbox.move_child(synth_root, synth_toggle_row.get_index() + 1)
	_update_synth_toggle_ui()

func _update_temperature_segment_ui():
	for i in range(temperature_buttons.size()):
		var b = temperature_buttons[i]
		var is_sel = (i + 1) == selected_temperature
		b.set_block_signals(true)
		b.button_pressed = is_sel
		b.set_block_signals(false)
		b.modulate = Color(0.80, 0.88, 1.0, 1.0) if is_sel else Color(1, 1, 1, 1)

func _on_temperature_segment_toggled(pressed: bool, temp_value: int):
	if not pressed:
		return
	selected_temperature = temp_value
	_update_temperature_segment_ui()

func _update_pressure_toggle_ui():
	if pressure_low_btn:
		pressure_low_btn.set_block_signals(true)
		pressure_low_btn.button_pressed = selected_pressure == "low"
		pressure_low_btn.set_block_signals(false)
		pressure_low_btn.modulate = Color(0.80, 0.88, 1.0, 1.0) if selected_pressure == "low" else Color(1, 1, 1, 1)
	if pressure_high_btn:
		pressure_high_btn.set_block_signals(true)
		pressure_high_btn.button_pressed = selected_pressure == "high"
		pressure_high_btn.set_block_signals(false)
		pressure_high_btn.modulate = Color(0.80, 0.88, 1.0, 1.0) if selected_pressure == "high" else Color(1, 1, 1, 1)

func _on_pressure_toggled(pressed: bool, pressure_value: String):
	if not pressed:
		return
	selected_pressure = pressure_value
	_update_pressure_toggle_ui()

func _set_tab(tab_name: String):
	current_tab = tab_name
	var is_gacha = tab_name == "gacha"
	var is_synthesize = tab_name == "synthesize"
	icon_row.visible = is_gacha
	result_panel.visible = is_gacha
	inventory_panel.visible = is_gacha or is_synthesize
	if synth_toggle_row:
		synth_toggle_row.visible = is_synthesize
	_update_synth_toggle_ui()
	tab_placeholder_label.visible = not is_gacha

	if tab_name == "synthesize":
		tab_placeholder_label.text = "1) 주기율표에서 원소 선택  2) 선택 원소/조건 보기로 전환  3) 합성"
		_log_debug("SYNTH", "합성 탭 진입")
		_apply_periodic_layout_for_synth()
	elif tab_name == "decompose":
		tab_placeholder_label.text = "돌 분해 탭 준비 중"
	else:
		tab_placeholder_label.text = ""
		if draw_label:
			draw_label.text = "뽑기"
		_apply_periodic_layout_for_gacha()

	_apply_tab_visuals()
	_refresh_action_button_state()

func _on_tab_gacha_pressed():
	_set_tab("gacha")

func _on_tab_synthesize_pressed():
	_set_tab("synthesize")

func _on_tab_decompose_pressed():
	_set_tab("decompose")

func _build_ratio_payload() -> Dictionary:
	var payload: Dictionary = {}
	for sym in selected_order:
		if selected_ingredients.has(sym):
			payload[sym] = float(selected_ratios.get(sym, 1))
	return payload

func _rebuild_selected_list():
	if selected_rows == null:
		return
	for c in selected_rows.get_children():
		c.queue_free()

	if selected_ingredients.is_empty():
		selected_empty_label = Label.new()
		selected_empty_label.text = "주기율표에서 원소를 선택하세요."
		selected_empty_label.add_theme_font_size_override("font_size", 18)
		selected_empty_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
		selected_rows.add_child(selected_empty_label)
		if selected_summary_label:
			selected_summary_label.text = "1회분 소모 총량: 0 / 300"
		return

	var ratio_sum := 0
	for sym in selected_order:
		if selected_ingredients.has(sym):
			ratio_sum += int(max(1, selected_ratios.get(sym, 1)))
	if ratio_sum <= 0:
		ratio_sum = 1

	var total_consumed := 0.0
	for sym in selected_order:
		if not selected_ingredients.has(sym):
			continue
		var ratio_val := int(max(1, selected_ratios.get(sym, 1)))
		var percent := (float(ratio_val) / float(ratio_sum)) * 100.0
		var consumed := 300.0 * float(ratio_val) / float(ratio_sum)
		total_consumed += consumed

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var info = Label.new()
		info.text = "%s (보유 %s)" % [sym, _format_amount(selected_ingredients[sym])]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
		info.custom_minimum_size = Vector2(170, 0)

		var ratio_label = Label.new()
		ratio_label.text = "비"
		ratio_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
		var ratio_spin = SpinBox.new()
		ratio_spin.min_value = 1
		ratio_spin.max_value = 999
		ratio_spin.step = 1
		ratio_spin.value = ratio_val
		ratio_spin.custom_minimum_size = Vector2(66, 0)
		ratio_spin.value_changed.connect(_on_ratio_spin_changed.bind(sym))

		var ratio_slider = HSlider.new()
		ratio_slider.min_value = 1
		ratio_slider.max_value = 99
		ratio_slider.step = 1
		ratio_slider.value = clampf(percent, 1.0, 99.0)
		ratio_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ratio_slider.custom_minimum_size = Vector2(130, 0)
		ratio_slider.value_changed.connect(_on_ratio_slider_preview_changed.bind(sym, ratio_spin))
		ratio_slider.drag_ended.connect(_on_ratio_slider_drag_ended.bind(sym, ratio_slider))

		var percent_label = Label.new()
		percent_label.text = "%.1f%% / 소모 %s" % [percent, _format_amount(consumed)]
		percent_label.custom_minimum_size = Vector2(138, 0)
		percent_label.add_theme_color_override("font_color", Color(0.20, 0.20, 0.20, 1))
		ratio_slider.value_changed.connect(_on_ratio_slider_label_preview.bind(sym, percent_label))

		var remove_btn = Button.new()
		remove_btn.text = "x"
		remove_btn.custom_minimum_size = Vector2(34, 0)
		remove_btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
		remove_btn.pressed.connect(_on_remove_selected.bind(sym))

		row.add_child(info)
		row.add_child(ratio_label)
		row.add_child(ratio_spin)
		row.add_child(ratio_slider)
		row.add_child(percent_label)
		row.add_child(remove_btn)
		selected_rows.add_child(row)
	if selected_summary_label:
		selected_summary_label.text = "1회분 소모 총량: %s / 300" % _format_amount(total_consumed)

func _set_ratio_and_refresh(symbol: String, value: float):
	selected_ratios[symbol] = int(clampf(round(value), 1.0, 999.0))
	_rebuild_selected_list()

func _on_ratio_spin_changed(value: float, symbol: String):
	_set_ratio_and_refresh(symbol, value)
	_log_debug("SYNTH", "비율 입력 변경", {"symbol": symbol, "ratio": selected_ratios[symbol]})

func _calc_target_ratio_from_percent(symbol: String, value: float) -> int:
	var other_sum := 0
	for sym in selected_order:
		if sym == symbol or not selected_ingredients.has(sym):
			continue
		other_sum += int(max(1, selected_ratios.get(sym, 1)))
	if other_sum <= 0:
		other_sum = 1
	var p = clampf(value / 100.0, 0.01, 0.99)
	return int(clampf(round((p * float(other_sum)) / maxf(0.0001, 1.0 - p)), 1.0, 999.0))

func _on_ratio_slider_preview_changed(value: float, symbol: String, ratio_spin: SpinBox):
	var target_ratio = _calc_target_ratio_from_percent(symbol, value)
	selected_ratios[symbol] = target_ratio
	ratio_spin.set_block_signals(true)
	ratio_spin.value = target_ratio
	ratio_spin.set_block_signals(false)

func _on_ratio_slider_label_preview(value: float, symbol: String, percent_label: Label):
	var target_ratio = _calc_target_ratio_from_percent(symbol, value)
	var other_sum := 0
	for sym in selected_order:
		if sym == symbol or not selected_ingredients.has(sym):
			continue
		other_sum += int(max(1, selected_ratios.get(sym, 1)))
	var total = max(1, other_sum + target_ratio)
	var pct = float(target_ratio) * 100.0 / float(total)
	var consumed = 300.0 * float(target_ratio) / float(total)
	percent_label.text = "%.1f%% / 소모 %s" % [pct, _format_amount(consumed)]

func _on_ratio_slider_drag_ended(value_changed: bool, symbol: String, ratio_slider: HSlider):
	if not value_changed:
		return
	var target_ratio = _calc_target_ratio_from_percent(symbol, ratio_slider.value)
	_set_ratio_and_refresh(symbol, target_ratio)
	_log_debug("SYNTH", "백분율 슬라이더 반영", {"symbol": symbol, "percent": ratio_slider.value, "ratio": target_ratio})

func _on_remove_selected(symbol: String):
	selected_ingredients.erase(symbol)
	selected_ratios.erase(symbol)
	selected_order.erase(symbol)
	var panel = periodic_cell_panels.get(symbol, null)
	if panel:
		_apply_periodic_cell_style(panel, MineralDatabase.is_element_valid(symbol), float(material_amounts.get(symbol, 0.0)), false)
	_rebuild_selected_list()
	_refresh_action_button_state()

func _find_trace_entry_index(el: String) -> int:
	for i in range(trace_entries.size()):
		var item = trace_entries[i]
		if str(item.get("element", "")) == el:
			return i
	return -1

func _build_trace_payload() -> Array:
	var payload: Array = []
	for item in trace_entries:
		payload.append({
			"element": str(item.get("element", "")),
			"amount_level": int(item.get("amount_level", 1))
		})
	return payload

func _prune_trace_entries():
	var kept: Array = []
	var seen: Dictionary = {}
	for item in trace_entries:
		var el = str(item.get("element", ""))
		var lvl = int(item.get("amount_level", 1))
		if el == "":
			continue
		if not TRACE_ELEMENTS.has(el):
			continue
		if seen.has(el):
			continue
		var available = float(material_amounts.get(el, 0.0))
		if available < float(max(1, lvl)):
			continue
		kept.append({"element": el, "amount_level": max(1, min(3, lvl))})
		seen[el] = true
		if kept.size() >= 3:
			break
	trace_entries = kept

func _refresh_trace_list_label():
	if trace_list_label == null:
		return
	if trace_entries.is_empty():
		trace_list_label.text = "미량원소 첨가: 없음"
		if trace_chip_row:
			for c in trace_chip_row.get_children():
				c.queue_free()
		return
	var chunks: Array[String] = []
	if trace_chip_row:
		for c in trace_chip_row.get_children():
			c.queue_free()
	for item in trace_entries:
		var el = str(item.get("element", ""))
		var lvl = int(item.get("amount_level", 1))
		chunks.append("%s x%d" % [el, lvl])
		if trace_chip_row:
			var chip = Button.new()
			chip.text = "[%s %d] x" % [el, lvl]
			chip.custom_minimum_size = Vector2(82, 26)
			chip.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
			chip.pressed.connect(_on_remove_trace_chip.bind(el, lvl))
			trace_chip_row.add_child(chip)
	trace_list_label.text = "미량원소 첨가: " + ", ".join(chunks)

func _on_add_trace_pressed():
	if trace_picker_popup == null:
		return
	trace_picker_popup.popup_centered(Vector2i(360, 180))

func _build_trace_picker_popup():
	trace_picker_popup = PopupPanel.new()
	trace_picker_popup.visible = false
	trace_picker_popup.size = Vector2(360, 220)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	trace_picker_popup.add_child(root)

	var title = Label.new()
	title.text = "미량원소 선택"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	root.add_child(title)

	var form_row = HBoxContainer.new()
	form_row.add_theme_constant_override("separation", 8)
	trace_popup_element_option = OptionButton.new()
	for el in TRACE_ELEMENTS:
		trace_popup_element_option.add_item(el)
	trace_popup_amount_option = OptionButton.new()
	trace_popup_amount_option.add_item("1개", 1)
	trace_popup_amount_option.add_item("2개", 2)
	trace_popup_amount_option.add_item("3개", 3)
	trace_popup_amount_option.selected = 0
	var confirm_btn = Button.new()
	confirm_btn.text = "추가"
	confirm_btn.custom_minimum_size = Vector2(68, 32)
	confirm_btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1))
	confirm_btn.pressed.connect(_on_trace_add_confirmed)
	form_row.add_child(trace_popup_element_option)
	form_row.add_child(trace_popup_amount_option)
	form_row.add_child(confirm_btn)
	root.add_child(form_row)

	synth_root.add_child(trace_picker_popup)

func _on_trace_add_confirmed():
	if trace_popup_element_option == null or trace_popup_amount_option == null:
		return
	var el = trace_popup_element_option.get_item_text(trace_popup_element_option.selected)
	var lvl = int(trace_popup_amount_option.get_selected_id())
	if lvl <= 0:
		lvl = 1
	lvl = min(3, lvl)
	var available = float(material_amounts.get(el, 0.0))
	if available < float(lvl):
		log_label.text = "%s 보유량이 부족합니다. (필요 %d / 보유 %s)" % [el, lvl, _format_amount(available)]
		if trace_picker_popup:
			trace_picker_popup.hide()
		return
	var idx = _find_trace_entry_index(el)
	if idx == -1 and trace_entries.size() >= 3:
		log_label.text = "미량원소는 최대 3개까지 선택할 수 있습니다."
		if trace_picker_popup:
			trace_picker_popup.hide()
		return
	if idx >= 0:
		trace_entries[idx]["amount_level"] = lvl
	else:
		trace_entries.append({"element": el, "amount_level": lvl})
	if trace_picker_popup:
		trace_picker_popup.hide()
	_refresh_trace_list_label()
	_log_debug("SYNTH", "미량 원소 추가", {"element": el, "amount_level": lvl})

func _on_remove_trace_chip(el: String, lvl: int):
	for i in range(trace_entries.size()):
		var item = trace_entries[i]
		if str(item.get("element", "")) == el and int(item.get("amount_level", 0)) == lvl:
			trace_entries.remove_at(i)
			break
	_refresh_trace_list_label()

# ==========================================================
# [수정된 부분] 인벤토리 불러오기 (함수 인자 오류 해결)
# ==========================================================
func refresh_inventory():
	_log_debug("INV", "인벤토리 갱신 요청 시작")
	
	material_amounts.clear()
		
	var http = HTTPRequest.new()
	add_child(http)
	
	# [수정] _n 인자를 제거하고, http 변수를 직접 큐프리 하도록 변경
	http.request_completed.connect(func(_r, code, _h, body):
		http.queue_free() # 여기서 직접 삭제
		
		var response_str = body.get_string_from_utf8()
		_log_debug("INV", "인벤토리 응답", {"code": code})
		
		if code != 200:
			log_label.text = "인벤토리 불러오기 실패: " + str(code)
			return

		var json = JSON.parse_string(response_str)
		
		if json is Array:
			if json.size() == 0:
				log_label.text = "보유한 원소가 없습니다."
				_log_debug("INV", "인벤토리가 비어있음")
			else:
				_log_debug("INV", "주기율표 데이터 반영", {"count": json.size()})
				for item in json:
					var symbol = str(item.get("element", ""))
					var amount = item.get("amount", 0)
					if symbol != "":
						material_amounts[symbol] = float(amount) if amount != null else 0.0
		else:
			_log_debug("INV", "데이터 형식 오류", {"value": json})
		_prune_trace_entries()
		_rebuild_periodic_table()
		_prune_selected_ingredients()
		_rebuild_selected_list()
		_refresh_trace_list_label()
		_refresh_action_button_state()
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
	periodic_cell_panels.clear()
	for child in inventory_list.get_children():
		child.queue_free()

	var cell_size = _get_periodic_cell_size()
	var row_start := 1
	var row_end := 10
	var visible_rows = (row_end - row_start + 1)
	inventory_list.custom_minimum_size = Vector2(
		float(cell_size * 18 + 2 * 17),
		float(cell_size * visible_rows + 2 * (visible_rows - 1))
	)

	for r in range(row_start, row_end + 1):
		for c in range(1, 19):
			var data = MineralDatabase.get_element_by_coord(r, c)
			if data:
				var sym = str(data.symbol)
				var amt = float(material_amounts.get(sym, 0))
				var in_recipe = MineralDatabase.is_element_valid(sym)
				_add_periodic_cell(sym, amt, in_recipe)
			else:
				var spacer = Control.new()
				spacer.custom_minimum_size = Vector2(cell_size, cell_size)
				inventory_list.add_child(spacer)

func _add_periodic_cell(symbol: String, amount: float, in_recipe: bool = true):
	var panel = PanelContainer.new()
	var cell_size = _get_periodic_cell_size()
	panel.custom_minimum_size = Vector2(cell_size, cell_size)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	_apply_periodic_cell_style(panel, in_recipe, amount, selected_ingredients.has(symbol))

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
	periodic_cell_panels[symbol] = panel
	panel.gui_input.connect(_on_periodic_cell_gui_input.bind(symbol, amount, in_recipe))

func _apply_periodic_cell_style(panel: PanelContainer, in_recipe: bool, amount: float, is_selected: bool):
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

	if not in_recipe:
		style.bg_color = Color(0.88, 0.88, 0.88, 1)
	elif amount > 1e-9:
		style.bg_color = Color(0.72, 0.88, 0.77, 1)
	else:
		style.bg_color = Color(0.90, 0.92, 0.90, 1)

	if is_selected:
		style.border_color = Color(0.12, 0.53, 0.35, 1)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

func _on_periodic_cell_gui_input(event: InputEvent, symbol: String, amount: float, in_recipe: bool):
	if current_tab != "synthesize":
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	if not in_recipe:
		log_label.text = "%s는 합성 레시피 대상이 아닙니다." % symbol
		_log_debug("SYNTH", "레시피 외 원소 선택 시도", {"symbol": symbol})
		return
	if amount <= 1e-9:
		log_label.text = "%s 보유량이 부족합니다." % symbol
		_log_debug("SYNTH", "보유량 없는 원소 선택 시도", {"symbol": symbol})
		return

	if selected_ingredients.has(symbol):
		selected_ingredients.erase(symbol)
		selected_ratios.erase(symbol)
		selected_order.erase(symbol)
	else:
		selected_ingredients[symbol] = amount
		selected_order.append(symbol)
		if not selected_ratios.has(symbol):
			selected_ratios[symbol] = 1

	var panel = periodic_cell_panels.get(symbol, null)
	if panel:
		_apply_periodic_cell_style(panel, in_recipe, amount, selected_ingredients.has(symbol))
	_rebuild_selected_list()
	_refresh_action_button_state()
	_log_debug("SYNTH", "선택 원소 갱신", {"selected": selected_ingredients.keys()})

func _prune_selected_ingredients():
	var to_remove: Array = []
	for sym in selected_ingredients.keys():
		var amt = float(material_amounts.get(sym, 0.0))
		if amt <= 1e-9:
			to_remove.append(sym)
	for sym in to_remove:
		selected_ingredients.erase(sym)
		selected_ratios.erase(sym)
		selected_order.erase(sym)

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

func _get_periodic_cell_size() -> int:
	return PERIODIC_CELL_SIZE_GACHA

func _apply_periodic_table_style(panel_min_height: float):
	inventory_panel.custom_minimum_size = Vector2(0, panel_min_height)
	inventory_list.add_theme_constant_override("h_separation", 2)
	inventory_list.add_theme_constant_override("v_separation", 2)

func _update_synth_layout():
	if current_tab != "synthesize":
		if synth_root:
			synth_root.visible = false
		if trace_picker_popup:
			trace_picker_popup.hide()
		return
	if is_synth_controls_collapsed:
		inventory_panel.visible = true
		# 주기율표 스케일은 뽑기 탭과 동일하게 유지.
		_apply_periodic_table_style(430.0)
		if synth_root:
			synth_root.visible = false
	else:
		inventory_panel.visible = false
		if synth_root:
			synth_root.visible = true
			var vh = get_viewport_rect().size.y
			var content_h = clampf(vh * 0.58, 280.0, 560.0)
			synth_root.custom_minimum_size = Vector2(0, content_h)
			if synth_left_panel:
				synth_left_panel.custom_minimum_size = Vector2(560, content_h)
			if synth_right_panel:
				synth_right_panel.custom_minimum_size = Vector2(420, content_h)
	call_deferred("_center_periodic_table")

func _apply_periodic_layout_for_synth():
	_apply_periodic_table_style(430.0)
	_update_synth_layout()
	call_deferred("refresh_inventory")

func _apply_periodic_layout_for_gacha():
	_apply_periodic_table_style(430.0)
	call_deferred("refresh_inventory")

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
	_log_debug("GACHA", "요청 시작")
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_gacha_completed.bind(http))
	
	var api_url = Auth.URL + "/rest/v1/rpc/purchase_element_pack"
	var headers = ["Content-Type: application/json", "apikey: " + Auth.KEY, "Authorization: Bearer " + Auth.access_token]
	
	var err = http.request(api_url, headers, HTTPClient.METHOD_POST, "{}")
	if err != OK:
		log_label.text = "뽑기 요청 실패: %d" % err
		_refresh_action_button_state()
		_log_debug("GACHA", "HTTP 요청 실패", {"error": err})

func _on_gacha_completed(_result, response_code, _headers, body, http_node):
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	_log_debug("GACHA", "응답 수신", {"code": response_code, "body": json})

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
	_refresh_action_button_state()

func _on_synthesize_pressed():
	if selected_ingredients.is_empty():
		log_label.text = "합성할 원소를 1개 이상 선택하세요."
		return

	var elements_ratio = _build_ratio_payload()
	if elements_ratio.is_empty():
		log_label.text = "비율을 설정해주세요."
		return

	var temperature = selected_temperature
	var pressure = selected_pressure
	var batch_count = 1
	var trace_payload = _build_trace_payload()
	for item in trace_payload:
		var el = str(item.get("element", ""))
		var lvl = int(item.get("amount_level", 1))
		var available = float(material_amounts.get(el, 0.0))
		if available < float(max(1, lvl)):
			log_label.text = "미량원소 %s 보유량이 부족합니다." % el
			return

	if btn_synthesize_exec:
		btn_synthesize_exec.disabled = true
	log_label.text = "합성 시뮬레이션 실행 중..."
	_log_debug("SYNTH", "요청 시작", {
		"elements_ratio": elements_ratio,
		"temperature": temperature,
		"pressure": pressure,
		"batch_count": batch_count,
		"trace_elements": trace_payload
	})

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_synthesize_completed.bind(http))

	var api_url = Auth.URL + "/rest/v1/rpc/synthesize_stone"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + Auth.KEY,
		"Authorization: Bearer " + Auth.access_token
	]
	# RPC 시그니처: elements_ratio, temperature, pressure, batch_count (trace_elements는 스키마 확장 후 전달)
	var body = JSON.stringify({
		"elements_ratio": elements_ratio,
		"temperature": temperature,
		"pressure": pressure,
		"batch_count": batch_count
	})
	var err = http.request(api_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		log_label.text = "합성 요청 실패: %d" % err
		if btn_synthesize_exec:
			btn_synthesize_exec.disabled = false
		_refresh_action_button_state()
		_log_debug("SYNTH", "HTTP 요청 실패", {"error": err})

func _on_synthesize_completed(_result, response_code, _headers, body, http_node):
	http_node.queue_free()
	var payload = JSON.parse_string(body.get_string_from_utf8())
	_log_debug("SYNTH", "응답 수신", {"code": response_code, "body": payload})

	if payload is Dictionary and response_code == 200 and payload.get("status") == "success":
		current_stone = int(payload.get("current_stone", current_stone))
		var minerals = GameManager.my_profile.get("minerals", {})
		if not (minerals is Dictionary):
			minerals = {}
		minerals["stone"] = current_stone
		GameManager.my_profile["minerals"] = minerals
		_refresh_stone_label()

		var mineral_name = str(payload.get("mineral_name", "Unknown"))
		var batch_factor = float(payload.get("batch_factor", 0.0))
		var stone_cost = int(payload.get("stone_cost", SYNTHESIS_COST_PER_BATCH))
		log_label.text = "합성 성공: %s (배치 %.3f, Stone -%d)" % [mineral_name, batch_factor, stone_cost]
		_update_result_display(payload.get("elements_consumed", {}))

		GameManager.fetch_user_stone()

		selected_ingredients.clear()
		selected_ratios.clear()
		selected_order.clear()
		trace_entries.clear()
		_rebuild_selected_list()
		_refresh_trace_list_label()
		refresh_inventory()
	else:
		var msg = "Unknown"
		if payload is Dictionary:
			msg = str(payload.get("message", msg))
			if payload.has("debug"):
				_log_debug("SYNTH", "서버 디버그 로그", payload.get("debug"))
		log_label.text = "합성 실패: " + msg

	if btn_synthesize_exec:
		btn_synthesize_exec.disabled = false
	_refresh_action_button_state()