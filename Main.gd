extends Node2D

func _ready():
	# 스크립트가 로드되자마자 출력하도록 맨 윗줄에 작성
	print("[DEBUG] Main script _ready called.")

	# 대기 코드(await) 삭제함. 즉시 설정 적용.
	get_window().transparent_bg = true
	get_window().transparent = true
	get_window().borderless = true

	print("[DEBUG] Calling Auth.sign_in...") 
	Auth.sign_in("test@fake.com", "wrong_pass")
