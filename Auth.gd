extends Node

# ▼ 본인 정보 (보여주신 키 그대로 넣었습니다) ▼
const URL = "https://qrfulgjculsbtxgyfzpk.supabase.co"
const KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyZnVsZ2pjdWxzYnR4Z3lmenBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwMzc4MzgsImV4cCI6MjA3OTYxMzgzOH0.H1jMawnCj0p2tJtYDYQICcQkfWpVqF5OsJImrMVlDV8"
# ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

signal login_success
signal login_failed(error_message)

func sign_in(email, password):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http))
	
	var api_url = URL + "/auth/v1/token?grant_type=password"
	var headers = ["Content-Type: application/json", "apikey: " + KEY]
	var body = JSON.stringify({"email": email, "password": password})
	
	print("[INFO] 서버에 로그인 요청을 보냅니다...")
	var error = http.request(api_url, headers, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		print("[ERROR] 요청 전송 실패. 에러코드: ", error)
		emit_signal("login_failed", "HTTP Request Error")
		http.queue_free()

# 안 쓰는 변수 앞에 언더바(_)를 붙여서 노란 경고를 없앴습니다.
func _on_request_completed(_result, response_code, _headers, body, http_node):
	# 서버가 보낸 편지 내용을 뜯어봅니다.
	var response_string = body.get_string_from_utf8()
	var response = JSON.parse_string(response_string)
	
	print("--- [서버 응답 도착] 코드: ", response_code, " ---")
	print("--- [내용] ", response_string) 

	if response_code == 200:
		print("[SUCCESS] 로그인 성공! User ID: ", response.user.id)
		emit_signal("login_success")
	elif response_code == 400:
		# 400 에러가 뜨면 연결은 성공한 것입니다! (비밀번호가 틀렸을 뿐)
		print("[CHECK] 서버 연결 성공! (비밀번호 틀림 메시지 수신함)")
		emit_signal("login_failed", "Invalid credentials")
	else:
		print("[ERROR] 서버 에러 발생: ", response_code)
		emit_signal("login_failed", "Server Error: " + str(response_code))
	
	http_node.queue_free()