extends Control

# 경로를 직접 지정 (상대 경로)
@onready var cell_scene = preload("res://ElementCell.tscn")
var grid: GridContainer

func _ready():
	print("1. [Debug] PeriodicTable 스크립트 진입")
	
	# 직접 경로로 노드 찾기 시도
	grid = get_node_or_null("ScrollContainer/CenterContainer/TableGrid")
	
	if grid == null:
		print("2. [Error] TableGrid 노드를 찾지 못했습니다. 경로를 확인하세요!")
		# 현재 자식 노드들을 출력해서 경로 문제를 파악합니다.
		print("현재 자식들: ", get_children())
		return
		
	print("2. [Success] TableGrid 노드 연결 성공! 배치를 시작합니다.")
	setup_periodic_table()

func setup_periodic_table():
	print("3. [Logic] setup_periodic_table 함수 시작")
	
	# 기존 노드 청소
	for child in grid.get_children():
		child.queue_free()
	
	var cell_count = 0
	var spacer_count = 0
	
	for r in range(1, 11):
		for c in range(1, 19):
			var element_data = MineralDatabase.get_element_by_coord(r, c)
			if element_data:
				_create_element_cell(element_data)
				cell_count += 1
			else:
				_create_spacer()
				spacer_count += 1
	
	print("4. [Done] 배치 완료 - 원소: ", cell_count, "개, 빈 칸: ", spacer_count, "개")

func _create_element_cell(data):
	var cell = cell_scene.instantiate()
	grid.add_child(cell)
	
	var label = cell.get_node_or_null("Label")
	if label:
		label.text = data.symbol
	
	# 66종 유효 원소 여부에 따른 시각적 구분
	if MineralDatabase.is_element_valid(data.symbol):
		cell.modulate = Color("#BDD9BF") # 보유/활성 후보 (민트)
	else:
		cell.modulate = Color(1, 1, 1, 0.2) # 배경 (흐리게)

func _create_spacer():
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(60, 60)
	grid.add_child(spacer)
