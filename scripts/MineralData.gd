extends Resource
class_name MineralData

@export var name: String
@export var formula: String
@export var elements: Dictionary  # {"Fe": 1, "S": 2} 등
@export var base_density: float
@export var base_color: Color
@export var crystal_system: String
@export var dna: Dictionary       # 시각화용 추가 데이터