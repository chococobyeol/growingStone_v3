extends PanelContainer

# 나중에 원소 데이터를 담을 변수
var element_data: Dictionary

func _ready():
	# 마우스가 들어오고 나갈 때의 신호를 연결합니다.
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 확대를 위해 피벗(중심점)을 중앙으로 설정합니다.
	pivot_offset = size / 2

func _on_mouse_entered():
	# 1.5배 확대하고 맨 위로 올립니다.
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_BACK)
	z_index = 10 # 주변 칸 위로 올라오게 함

func _on_mouse_exited():
	# 원래 크기로 복구합니다.
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	z_index = 0