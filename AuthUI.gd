extends Control

const COLOR_TEXT_SECONDARY := Color("555555")
const COLOR_ERROR := Color("D9534F")
const COLOR_SUCCESS := Color("2E7D32")
var is_dragging_window := false
var drag_offset := Vector2i.ZERO

@onready var email_input = $CenterContainer/Card/CardMargin/VBox/EmailInput
@onready var password_input = $CenterContainer/Card/CardMargin/VBox/PasswordInput
@onready var signin_button = $CenterContainer/Card/CardMargin/VBox/SigninButton
@onready var signup_button = $CenterContainer/Card/CardMargin/VBox/SignupButton
@onready var status_label = $CenterContainer/Card/CardMargin/VBox/StatusLabel
@onready var ko_button = $CenterContainer/Card/CardMargin/VBox/LangRow/KoButton
@onready var en_button = $CenterContainer/Card/CardMargin/VBox/LangRow/EnButton
@onready var card = $CenterContainer/Card
@onready var close_button = $CloseButton

func _ready():
	_connect_signals_once()
	_set_status("", COLOR_TEXT_SECONDARY)
	if GameManager.profile_error_message != "":
		_set_status(GameManager.profile_error_message, COLOR_ERROR)
		GameManager.profile_error_message = ""
	await get_tree().process_frame
	_position_close_button()

func _connect_signals_once():
	if not signin_button.pressed.is_connected(_on_signin_pressed):
		signin_button.pressed.connect(_on_signin_pressed)
	if not signup_button.pressed.is_connected(_on_signup_pressed):
		signup_button.pressed.connect(_on_signup_pressed)
	if not ko_button.pressed.is_connected(_on_ko_pressed):
		ko_button.pressed.connect(_on_ko_pressed)
	if not en_button.pressed.is_connected(_on_en_pressed):
		en_button.pressed.connect(_on_en_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not Auth.auth_success.is_connected(_on_auth_success):
		Auth.auth_success.connect(_on_auth_success)
	if not Auth.auth_failed.is_connected(_on_auth_failed):
		Auth.auth_failed.connect(_on_auth_failed)

func _on_signin_pressed():
	if _check_input():
		_set_loading(true, "로그인 중...")
		Auth.sign_in(email_input.text.strip_edges().to_lower(), password_input.text)

func _on_signup_pressed():
	if _check_input():
		_set_loading(true, "회원가입 중...")
		Auth.sign_up(email_input.text.strip_edges().to_lower(), password_input.text)

func _check_input():
	if email_input.text.strip_edges() == "" or password_input.text == "":
		_set_status("이메일과 비밀번호를 입력해주세요.", COLOR_ERROR)
		return false
	return true

func _on_auth_success():
	_set_loading(false)
	_set_status("성공! 메인 화면으로 이동합니다.", COLOR_SUCCESS)
	# export 환경에서 파일명 대소문자까지 정확히 일치해야 함.
	var err := get_tree().change_scene_to_file("res://main.tscn")
	if err != OK:
		_set_status("오류: 메인 씬 로드 실패 (%d)" % err, COLOR_ERROR)

func _on_auth_failed(msg):
	_set_loading(false)
	_set_status("오류: " + str(msg), COLOR_ERROR)

func _set_loading(is_loading: bool, message: String = ""):
	signin_button.disabled = is_loading
	signup_button.disabled = is_loading
	if message != "":
		_set_status(message, COLOR_TEXT_SECONDARY)

func _set_status(message: String, color: Color):
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)

func _on_ko_pressed():
	_set_status("언어: 한국어", COLOR_TEXT_SECONDARY)

func _on_en_pressed():
	_set_status("Language: English", COLOR_TEXT_SECONDARY)

func _on_close_pressed():
	get_tree().quit()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging_window = true
			drag_offset = DisplayServer.mouse_get_position() - get_window().position
		else:
			is_dragging_window = false

func _process(_delta):
	if is_dragging_window and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_window().position = DisplayServer.mouse_get_position() - drag_offset
	elif is_dragging_window:
		is_dragging_window = false

func _notification(what):
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_position_close_button()

func _position_close_button():
	# 카드 우상단 바깥 코너에 고정 배치
	var btn_size = close_button.size
	var card_pos = card.position
	var card_size = card.size
	close_button.position = card_pos + Vector2(card_size.x - btn_size.x * 0.62, -btn_size.y * 0.38)