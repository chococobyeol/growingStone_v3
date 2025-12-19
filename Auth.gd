extends Node

# ▼ 본인 정보 입력 (따옴표 지우지 마세요!) ▼
const URL = "https://qrfulgjculsbtxgyfzpk.supabase.co"
const KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyZnVsZ2pjdWxzYnR4Z3lmenBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMzc4MzgsImV4cCI6MjA3OTYxMzgzOH0.H1jMawnCj0p2tJtYDYQICcQkfWpVqF5OsJImrMVlDV8"
# ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

signal auth_success
signal auth_failed(error_message)

# [여기가 추가되어야 합니다] 토큰과 유저 ID를 저장할 변수
var access_token = ""
var user_id = ""

func sign_in(email, password):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_signin_completed.bind(http))
	
	var api_url = URL + "/auth/v1/token?grant_type=password"
	var headers = ["Content-Type: application/json", "apikey: " + KEY]
	var body = JSON.stringify({"email": email, "password": password})
	
	print("[INFO] Sending Sign In request...")
	var error = http.request(api_url, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		print("[ERROR] HTTP Request failed. Code: ", error)
		emit_signal("auth_failed", "HTTP Request Error")
		http.queue_free()

func sign_up(email, password):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_signup_completed.bind(http))
	
	var api_url = URL + "/auth/v1/signup"
	var headers = ["Content-Type: application/json", "apikey: " + KEY]
	var body = JSON.stringify({"email": email, "password": password})
	
	print("[INFO] Sending Sign Up request...")
	var error = http.request(api_url, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		print("[ERROR] HTTP Request failed. Code: ", error)
		emit_signal("auth_failed", "HTTP Request Error")
		http.queue_free()

func _on_signin_completed(_result, response_code, _headers, body, http_node):
	var response_string = body.get_string_from_utf8()
	var response = JSON.parse_string(response_string)
	
	print("[DEBUG] Sign In Response: ", response_code)
	
	if response_code == 200:
		# [중요] 로그인 성공 시 변수에 토큰 저장
		access_token = response.access_token
		user_id = response.user.id
		print("[SUCCESS] Sign In successful. ID: ", user_id)
		emit_signal("auth_success")
	elif response_code == 400:
		print("[ERROR] Sign In failed: Invalid credentials")
		emit_signal("auth_failed", "Invalid email or password")
	else:
		print("[ERROR] Server Error: ", response_code)
		var msg = "Server Error"
		if response and response.has("error_description"):
			msg = response.error_description
		emit_signal("auth_failed", msg)
	
	http_node.queue_free()

func _on_signup_completed(_result, response_code, _headers, body, http_node):
	var response_string = body.get_string_from_utf8()
	var response = JSON.parse_string(response_string)

	print("[DEBUG] Sign Up Response: ", response_code)

	if response_code == 200 or response_code == 201:
		print("[SUCCESS] Sign Up successful.")
		emit_signal("auth_success")
	else:
		print("[ERROR] Sign Up failed: ", response_code)
		var msg = "Sign Up Failed"
		if response and response.has("msg"): msg = response.msg
		elif response and response.has("error_description"): msg = response.error_description
		elif response and response.has("message"): msg = response.message
		emit_signal("auth_failed", msg)
	
	http_node.queue_free()