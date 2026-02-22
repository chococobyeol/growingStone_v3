extends Node

# 데이터 저장용 변수
var my_profile = {} 
var my_stone = {}   

# 신호 정의
signal data_loaded        # 데이터 로드 완료 (게임 시작)
signal no_stone_found     # 돌이 없음 (연구소/상점 화면으로 이동 필요)
signal profile_not_found  # 프로필 없음 (회원가입 필요)

var profile_error_message := ""  # profile_not_found 시 AuthUI에 전달할 메시지

# 1. 프로필 정보 가져오기
func fetch_user_profile():
	if Auth.access_token == "":
		print("[ERROR] No Auth Token.")
		return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_profile_fetched.bind(http))
	
	var api_url = Auth.URL + "/rest/v1/profiles?id=eq." + Auth.user_id + "&select=*"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + Auth.KEY,
		"Authorization: Bearer " + Auth.access_token
	]
	
	print("[INFO] Fetching Profile...")
	http.request(api_url, headers, HTTPClient.METHOD_GET)

# 2. 돌 정보 가져오기 (핵심: 레시피 정보 Join)
func fetch_user_stone():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_stone_fetched.bind(http))
	
	# [중요] foreign table인 mineral_recipes의 정보도 같이 가져오라는 문법
	var query = "select=*,mineral_recipes(*)"
	var api_url = Auth.URL + "/rest/v1/stones?owner_id=eq." + Auth.user_id + "&" + query
	
	var headers = [
		"Content-Type: application/json",
		"apikey: " + Auth.KEY,
		"Authorization: Bearer " + Auth.access_token
	]
	
	print("[INFO] Fetching Stone with Recipe...")
	http.request(api_url, headers, HTTPClient.METHOD_GET)

# [콜백] 프로필 로드 완료
func _on_profile_fetched(_result, response_code, _headers, body, http_node):
	var json = JSON.parse_string(body.get_string_from_utf8())
	http_node.queue_free()

	if response_code != 200:
		print("[ERROR] Failed to load profile: ", response_code)
		return

	if json is Array and json.size() > 0:
		my_profile = json[0]
		print("[SUCCESS] Profile Loaded: ", my_profile.get("nickname"))
		fetch_user_stone()
		return

	# 프로필 없음 → 로그인 화면으로 돌려보냄 (회원가입 유도)
	print("[ERROR] Profile not found. Account not registered.")
	profile_error_message = "이 계정은 등록되지 않았습니다. 회원가입을 진행해주세요."
	emit_signal("profile_not_found")

# [콜백] 돌 정보 로드 완료
func _on_stone_fetched(_result, response_code, _headers, body, http_node):
	var json = JSON.parse_string(body.get_string_from_utf8())
	http_node.queue_free()
	
	if response_code == 200:
		if json.size() > 0:
			# 돌이 있으면 데이터 저장
			my_stone = json[0]
			var recipe_name = my_stone.get("mineral_recipes", {}).get("name", "Unknown")
			print("[SUCCESS] Stone Found! Type: ", recipe_name)
			emit_signal("data_loaded")
		else:
			# 돌이 없으면 신호 발생 (연구소 UI 띄우기 위함)
			print("[INFO] No stone found. Requesting Synthesis...")
			emit_signal("no_stone_found")
	else:
		print("[ERROR] Failed to load stone: ", response_code)
