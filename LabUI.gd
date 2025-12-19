extends Control

# UI 노드 참조
@onready var log_label = $LogLabel
@onready var btn_gacha = $BtnGacha
@onready var btn_close = $BtnClose
@onready var btn_synthesize = $BtnSynthesize
@onready var inventory_list = $ScrollContainer/InventoryList

# 선택된 재료 저장소
var selected_ingredients = {}

func _ready():
	# 버튼 연결
	btn_gacha.pressed.connect(_on_gacha_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	
	if btn_synthesize:
		btn_synthesize.pressed.connect(_on_synthesize_pressed)
	
	# 연구소가 보일 때마다 인벤토리 갱신
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		log_label.text = "연구소에 오신 것을 환영합니다."
		selected_ingredients.clear()
		refresh_inventory()

func _on_close_pressed():
	visible = false
	var main = get_tree().current_scene
	if main.has_method("apply_widget_mode"):
		main.apply_widget_mode()
	GameManager.fetch_user_stone()

# ==========================================================
# [수정된 부분] 인벤토리 불러오기 (함수 인자 오류 해결)
# ==========================================================
func refresh_inventory():
	print("[DEBUG] 인벤토리 갱신 요청 시작...")
	
	# 기존 목록 UI 삭제
	for child in inventory_list.get_children():
		child.queue_free()
		
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
				print("[DEBUG] UI 생성 시작: ", json.size(), "개 항목")
				for item in json:
					add_inventory_slot(item)
		else:
			print("[ERROR] 데이터 형식이 배열이 아닙니다: ", json)
	)
	
	# 보유량이 0보다 큰 재료만 요청
	var api_url = Auth.URL + "/rest/v1/user_materials?user_id=eq." + Auth.user_id + "&amount=gt.0"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + Auth.KEY, 
		"Authorization: Bearer " + Auth.access_token
	]
	http.request(api_url, headers, HTTPClient.METHOD_GET)

func add_inventory_slot(item_data):
	var element = item_data["element"]
	var amount = item_data["amount"]
	
	print("[DEBUG] 슬롯 생성 시도: ", element)
	
	# HBoxContainer 생성
	var hbox = HBoxContainer.new()
	
	# [핵심 수정 1] 강제로 높이와 너비를 지정합니다.
	# 이걸 안 하면 내용물이 있어도 높이 0이 되어 안 보일 수 있습니다.
	hbox.custom_minimum_size.y = 50   # 높이 50px 확보
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL # 가로로 꽉 채우기
	
	# 라벨
	var label = Label.new()
	label.text = "%s : %d개" % [element, amount]
	label.custom_minimum_size.x = 150
	
	# [핵심 수정 2] 라벨 글자가 세로 중앙에 오도록 설정
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER 
	
	# 스핀박스
	var spin = SpinBox.new()
	spin.min_value = 0
	spin.max_value = amount
	spin.value = 0
	
	# [핵심 수정 3] 스핀박스도 세로 중앙 정렬 플래그 추가
	spin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 값 변경 연결
	spin.value_changed.connect(func(val): 
		if val > 0:
			selected_ingredients[element] = int(val)
		else:
			selected_ingredients.erase(element)
		print("현재 선택된 레시피: ", selected_ingredients)
	)
	
	hbox.add_child(label)
	hbox.add_child(spin)
	
	inventory_list.add_child(hbox)

# ==========================================================
# Gacha (뽑기)
# ==========================================================
func _on_gacha_pressed():
	btn_gacha.disabled = true
	log_label.text = "원소 추출 중..."
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_gacha_completed.bind(http))
	
	var api_url = Auth.URL + "/rest/v1/rpc/purchase_element_pack"
	var headers = ["Content-Type: application/json", "apikey: " + Auth.KEY, "Authorization: Bearer " + Auth.access_token]
	
	http.request(api_url, headers, HTTPClient.METHOD_POST, "{}")

func _on_gacha_completed(_result, response_code, _headers, body, http_node):
	btn_gacha.disabled = false
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	print("Gacha Result: ", json)
	
	if response_code == 200 and json.get("status") == "success":
		var elem = json.get("element")
		var amt = json.get("amount")
		var stone_bal = json.get("current_stone")
		log_label.text = "획득! %s x%d (Stone: %d)" % [elem, amt, stone_bal]
		refresh_inventory() # 획득 후 즉시 목록 갱신
	else:
		log_label.text = "실패: " + json.get("message", "Unknown")

# ==========================================================
# 합성 (Synthesize)
# ==========================================================
func _on_synthesize_pressed():
	if selected_ingredients.is_empty():
		log_label.text = "재료를 선택해주세요!"
		return
		
	btn_synthesize.disabled = true
	log_label.text = "합성 시도 중..."
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_synthesize_completed.bind(http))
	
	var api_url = Auth.URL + "/rest/v1/rpc/synthesize_stone"
	var headers = ["Content-Type: application/json", "apikey: " + Auth.KEY, "Authorization: Bearer " + Auth.access_token]
	var body = JSON.stringify({"ingredients": selected_ingredients})
	
	http.request(api_url, headers, HTTPClient.METHOD_POST, body)

func _on_synthesize_completed(_result, response_code, _headers, body, http_node):
	btn_synthesize.disabled = false
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	print("Synthesis Result: ", json)
	
	if response_code == 200 and json.get("status") == "success":
		log_label.text = "대성공! [" + json.get("stone_name") + "] 탄생!"
		await get_tree().create_timer(1.5).timeout
		_on_close_pressed()
	else:
		log_label.text = "실패: " + json.get("message", "Unknown")
		refresh_inventory()