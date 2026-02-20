extends Node

var URL := ""
var KEY := ""
const FALLBACK_SUPABASE_URL := "https://xfjlxtdhnwwenkpcvtpv.supabase.co"
const FALLBACK_SUPABASE_ANON_KEY := "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhmamx4dGRobnd3ZW5rcGN2dHB2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0OTk5NjAsImV4cCI6MjA4NzA3NTk2MH0.DDf5RAUaPZWiheeXKeN9KVlsuiVW31g9HFxzCfLLLT0"

signal auth_success
signal auth_failed(error_message)

# [여기가 추가되어야 합니다] 토큰과 유저 ID를 저장할 변수
var access_token = ""
var user_id = ""

func _ready():
	_load_auth_config()

func _load_auth_config():
	URL = FALLBACK_SUPABASE_URL
	KEY = FALLBACK_SUPABASE_ANON_KEY
	print("[INFO] Supabase auth config loaded (hardcoded).")

func _ensure_auth_config() -> bool:
	if URL == "" or KEY == "":
		_load_auth_config()

	if URL == "" or KEY == "":
		var msg = "Missing SUPABASE_URL or SUPABASE_ANON_KEY."
		print("[ERROR] ", msg)
		emit_signal("auth_failed", msg)
		return false
	return true

func sign_in(email, password):
	if not _ensure_auth_config():
		return

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
	if not _ensure_auth_config():
		return

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
		# Supabase 설정에 따라 signup 응답에 session(access_token)이 없을 수 있음.
		if response and response.has("access_token") and response.has("user"):
			access_token = str(response.access_token)
			user_id = str(response.user.id)
			print("[SUCCESS] Sign Up successful. ID: ", user_id)
			emit_signal("auth_success")
		elif response and response.has("user"):
			user_id = str(response.user.id)
			print("[INFO] Sign Up completed, but no session token returned.")
			emit_signal("auth_failed", "가입 완료. 이메일 인증 후 로그인해주세요.")
		else:
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