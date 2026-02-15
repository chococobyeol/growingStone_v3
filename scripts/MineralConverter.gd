@tool
extends Node

# 인스펙터에서 클릭하여 실행하는 버튼
@export var execute_convert: bool = false:
	set(value):
		if value:
			convert_v15_data()
		execute_convert = false

# 고증 데이터 경로 (v15 확인)
const CSV_PATH = "res://data_audit/minerals_audit_v15.csv"
const SAVE_PATH = "res://assets/data/mineral_database.res"

func convert_v15_data():
	print("🚀 [v15] 고증 데이터베이스 변환 프로세스 시작...")
	
	if not FileAccess.file_exists(CSV_PATH):
		printerr("❌ 에러: CSV 파일을 찾을 수 없습니다: ", CSV_PATH)
		return

	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		printerr("❌ 에러: 파일을 열 수 없습니다.")
		return

	# 헤더 스킵
	var _header = file.get_csv_line()
	
	var database = {}
	var count = 0

	# 파일 끝까지 정밀 읽기 (고도 4.5 호환)
	while file.get_position() < file.get_length():
		var line = file.get_csv_line()
		
		# v15 CSV 구조: name, formula, elements, density, color, crystal
		if line.size() < 6:
			continue
		
		var m = MineralData.new()
		m.name = line[0].strip_edges()
		m.formula = line[1].strip_edges()
		
		# JSON 성분 데이터 파싱
		var elements_res = JSON.parse_string(line[2])
		if elements_res != null:
			m.elements = elements_res
		
		m.base_density = float(line[3])
		m.base_color = Color(line[4].strip_edges())
		m.crystal_system = line[5].strip_edges()
		
		# 고증 기반 DNA 생성
		m.dna = _generate_v15_dna(m.crystal_system, m.base_color)
		
		database[m.name] = m
		count += 1

	# 저장 경로 확보
	if not DirAccess.dir_exists_absolute("res://assets/data/"):
		DirAccess.make_dir_recursive_absolute("res://assets/data/")
	
	# Dictionary 데이터를 포함한 리소스 생성 및 저장
	var db_resource = Resource.new()
	db_resource.set_meta("data", database)
	
	var err = ResourceSaver.save(db_resource, SAVE_PATH)
	if err == OK:
		print("✨ [v15] 변환 대성공!")
		print("- 등록된 순수 광물 수: ", count, "개")
		print("- 저장 완료: ", SAVE_PATH)
	else:
		printerr("❌ 리소스 저장 실패 (에러 코드: ", err, ")")

# 시각화 고증을 위한 DNA 내부 생성 함수
func _generate_v15_dna(sys_name: String, color: Color) -> Dictionary:
	# GDScript 4.x에서는 to_lower()를 사용합니다.
	var sys = sys_name.to_lower()
	var is_transparent = 1 if color == Color.WHITE else 0
	
	var dna = {
		"system": sys,
		"scale": [1.0, 1.0, 1.0],
		"optical": {
			"transparent": is_transparent,
			"refraction": 1.5 if is_transparent else 0.0,
			"birefringence": 0.01 if sys != "cubic" and is_transparent else 0.0
		}
	}
	
	if "tetragonal" in sys: dna["scale"] = [1.0, 1.0, 1.4]
	elif "hexagonal" in sys or "trigonal" in sys: dna["scale"] = [1.0, 1.0, 1.6]
	elif "orthorhombic" in sys: dna["scale"] = [0.8, 1.0, 1.2]
	elif "monoclinic" in sys or "triclinic" in sys: dna["scale"] = [0.7, 1.0, 1.3]
	
	return dna