extends Node

# --- [1] 주기율표 정밀 좌표 데이터 (118 원소) ---
# row: 1~10 (9,10은 하단 란타넘/악티늄족), col: 1~18
const PERIODIC_TABLE_DATA = {
	1: {"symbol": "H", "name": "Hydrogen", "row": 1, "col": 1},
	2: {"symbol": "He", "name": "Helium", "row": 1, "col": 18},
	3: {"symbol": "Li", "name": "Lithium", "row": 2, "col": 1},
	4: {"symbol": "Be", "name": "Beryllium", "row": 2, "col": 2},
	5: {"symbol": "B", "name": "Boron", "row": 2, "col": 13},
	6: {"symbol": "C", "name": "Carbon", "row": 2, "col": 14},
	7: {"symbol": "N", "name": "Nitrogen", "row": 2, "col": 15},
	8: {"symbol": "O", "name": "Oxygen", "row": 2, "col": 16},
	9: {"symbol": "F", "name": "Fluorine", "row": 2, "col": 17},
	10: {"symbol": "Ne", "name": "Neon", "row": 2, "col": 18},
	11: {"symbol": "Na", "name": "Sodium", "row": 3, "col": 1},
	12: {"symbol": "Mg", "name": "Magnesium", "row": 3, "col": 2},
	13: {"symbol": "Al", "name": "Aluminium", "row": 3, "col": 13},
	14: {"symbol": "Si", "name": "Silicon", "row": 3, "col": 14},
	15: {"symbol": "P", "name": "Phosphorus", "row": 3, "col": 15},
	16: {"symbol": "S", "name": "Sulfur", "row": 3, "col": 16},
	17: {"symbol": "Cl", "name": "Chlorine", "row": 3, "col": 17},
	18: {"symbol": "Ar", "name": "Argon", "row": 3, "col": 18},
	19: {"symbol": "K", "name": "Potassium", "row": 4, "col": 1},
	20: {"symbol": "Ca", "name": "Calcium", "row": 4, "col": 2},
	21: {"symbol": "Sc", "name": "Scandium", "row": 4, "col": 3},
	22: {"symbol": "Ti", "name": "Titanium", "row": 4, "col": 4},
	23: {"symbol": "V", "name": "Vanadium", "row": 4, "col": 5},
	24: {"symbol": "Cr", "name": "Chromium", "row": 4, "col": 6},
	25: {"symbol": "Mn", "name": "Manganese", "row": 4, "col": 7},
	26: {"symbol": "Fe", "name": "Iron", "row": 4, "col": 8},
	27: {"symbol": "Co", "name": "Cobalt", "row": 4, "col": 9},
	28: {"symbol": "Ni", "name": "Nickel", "row": 4, "col": 10},
	29: {"symbol": "Cu", "name": "Copper", "row": 4, "col": 11},
	30: {"symbol": "Zn", "name": "Zinc", "row": 4, "col": 12},
	31: {"symbol": "Ga", "name": "Gallium", "row": 4, "col": 13},
	32: {"symbol": "Ge", "name": "Germanium", "row": 4, "col": 14},
	33: {"symbol": "As", "name": "Arsenic", "row": 4, "col": 15},
	34: {"symbol": "Se", "name": "Selenium", "row": 4, "col": 16},
	35: {"symbol": "Br", "name": "Bromine", "row": 4, "col": 17},
	36: {"symbol": "Kr", "name": "Krypton", "row": 4, "col": 18},
	37: {"symbol": "Rb", "name": "Rubidium", "row": 5, "col": 1},
	38: {"symbol": "Sr", "name": "Strontium", "row": 5, "col": 2},
	39: {"symbol": "Y", "name": "Yttrium", "row": 5, "col": 3},
	40: {"symbol": "Zr", "name": "Zirconium", "row": 5, "col": 4},
	41: {"symbol": "Nb", "name": "Niobium", "row": 5, "col": 5},
	42: {"symbol": "Mo", "name": "Molybdenum", "row": 5, "col": 6},
	43: {"symbol": "Tc", "name": "Technetium", "row": 5, "col": 7},
	44: {"symbol": "Ru", "name": "Ruthenium", "row": 5, "col": 8},
	45: {"symbol": "Rh", "name": "Rhodium", "row": 5, "col": 9},
	46: {"symbol": "Pd", "name": "Palladium", "row": 5, "col": 10},
	47: {"symbol": "Ag", "name": "Silver", "row": 5, "col": 11},
	48: {"symbol": "Cd", "name": "Cadmium", "row": 5, "col": 12},
	49: {"symbol": "In", "name": "Indium", "row": 5, "col": 13},
	50: {"symbol": "Sn", "name": "Tin", "row": 5, "col": 14},
	51: {"symbol": "Sb", "name": "Antimony", "row": 5, "col": 15},
	52: {"symbol": "Te", "name": "Tellurium", "row": 5, "col": 16},
	53: {"symbol": "I", "name": "Iodine", "row": 5, "col": 17},
	54: {"symbol": "Xe", "name": "Xenon", "row": 5, "col": 18},
	55: {"symbol": "Cs", "name": "Caesium", "row": 6, "col": 1},
	56: {"symbol": "Ba", "name": "Barium", "row": 6, "col": 2},
	72: {"symbol": "Hf", "name": "Hafnium", "row": 6, "col": 4},
	73: {"symbol": "Ta", "name": "Tantalum", "row": 6, "col": 5},
	74: {"symbol": "W", "name": "Tungsten", "row": 6, "col": 6},
	75: {"symbol": "Re", "name": "Rhenium", "row": 6, "col": 7},
	76: {"symbol": "Os", "name": "Osmium", "row": 6, "col": 8},
	77: {"symbol": "Ir", "name": "Iridium", "row": 6, "col": 9},
	78: {"symbol": "Pt", "name": "Platinum", "row": 6, "col": 10},
	79: {"symbol": "Au", "name": "Gold", "row": 6, "col": 11},
	80: {"symbol": "Hg", "name": "Mercury", "row": 6, "col": 12},
	81: {"symbol": "Tl", "name": "Thallium", "row": 6, "col": 13},
	82: {"symbol": "Pb", "name": "Lead", "row": 6, "col": 14},
	83: {"symbol": "Bi", "name": "Bismuth", "row": 6, "col": 15},
	84: {"symbol": "Po", "name": "Polonium", "row": 6, "col": 16},
	85: {"symbol": "At", "name": "Astatine", "row": 6, "col": 17},
	86: {"symbol": "Rn", "name": "Radon", "row": 6, "col": 18},
	87: {"symbol": "Fr", "name": "Francium", "row": 7, "col": 1},
	88: {"symbol": "Ra", "name": "Radium", "row": 7, "col": 2},
	104: {"symbol": "Rf", "name": "Rutherfordium", "row": 7, "col": 4},
	105: {"symbol": "Db", "name": "Dubnium", "row": 7, "col": 5},
	106: {"symbol": "Sg", "name": "Seaborgium", "row": 7, "col": 6},
	107: {"symbol": "Bh", "name": "Bohrium", "row": 7, "col": 7},
	108: {"symbol": "Hs", "name": "Hassium", "row": 7, "col": 8},
	109: {"symbol": "Mt", "name": "Meitnerium", "row": 7, "col": 9},
	110: {"symbol": "Ds", "name": "Darmstadtium", "row": 7, "col": 10},
	111: {"symbol": "Rg", "name": "Roentgenium", "row": 7, "col": 11},
	112: {"symbol": "Cn", "name": "Copernicium", "row": 7, "col": 12},
	113: {"symbol": "Nh", "name": "Nihonium", "row": 7, "col": 13},
	114: {"symbol": "Fl", "name": "Flerovium", "row": 7, "col": 14},
	115: {"symbol": "Mc", "name": "Moscovium", "row": 7, "col": 15},
	116: {"symbol": "Lv", "name": "Livermorium", "row": 7, "col": 16},
	117: {"symbol": "Ts", "name": "Tennessine", "row": 7, "col": 17},
	118: {"symbol": "Og", "name": "Oganesson", "row": 7, "col": 18},
	57: {"symbol": "La", "name": "Lanthanum", "row": 9, "col": 4},
	58: {"symbol": "Ce", "name": "Cerium", "row": 9, "col": 5},
	59: {"symbol": "Pr", "name": "Praseodymium", "row": 9, "col": 6},
	60: {"symbol": "Nd", "name": "Neodymium", "row": 9, "col": 7},
	61: {"symbol": "Pm", "name": "Promethium", "row": 9, "col": 8},
	62: {"symbol": "Sm", "name": "Samarium", "row": 9, "col": 9},
	63: {"symbol": "Eu", "name": "Europium", "row": 9, "col": 10},
	64: {"symbol": "Gd", "name": "Gadolinium", "row": 9, "col": 11},
	65: {"symbol": "Tb", "name": "Terbium", "row": 9, "col": 12},
	66: {"symbol": "Dy", "name": "Dysprosium", "row": 9, "col": 13},
	67: {"symbol": "Ho", "name": "Holmium", "row": 9, "col": 14},
	68: {"symbol": "Er", "name": "Erbium", "row": 9, "col": 15},
	69: {"symbol": "Tm", "name": "Thulium", "row": 9, "col": 16},
	70: {"symbol": "Yb", "name": "Ytterbium", "row": 9, "col": 17},
	71: {"symbol": "Lu", "name": "Lutetium", "row": 9, "col": 18},
	89: {"symbol": "Ac", "name": "Actinium", "row": 10, "col": 4},
	90: {"symbol": "Th", "name": "Thorium", "row": 10, "col": 5},
	91: {"symbol": "Pa", "name": "Protactinium", "row": 10, "col": 6},
	92: {"symbol": "U", "name": "Uranium", "row": 10, "col": 7},
	93: {"symbol": "Np", "name": "Neptunium", "row": 10, "col": 8},
	94: {"symbol": "Pu", "name": "Plutonium", "row": 10, "col": 9},
	95: {"symbol": "Am", "name": "Americium", "row": 10, "col": 10},
	96: {"symbol": "Cm", "name": "Curium", "row": 10, "col": 11},
	97: {"symbol": "Bk", "name": "Berkelium", "row": 10, "col": 12},
	98: {"symbol": "Cf", "name": "Californium", "row": 10, "col": 13},
	99: {"symbol": "Es", "name": "Einsteinium", "row": 10, "col": 14},
	100: {"symbol": "Fm", "name": "Fermium", "row": 10, "col": 15},
	101: {"symbol": "Md", "name": "Mendelevium", "row": 10, "col": 16},
	102: {"symbol": "No", "name": "Nobelium", "row": 10, "col": 17},
	103: {"symbol": "Lr", "name": "Lawrencium", "row": 10, "col": 18}
}

# --- [2] 유효 원소 목록 (v15 변환 결과 기반 66종) ---
const VALID_ELEMENTS = [
	"Ag", "Al", "As", "Au", "B", "Ba", "Be", "Bi", "Br", "C", "Ca", "Cd", "Ce", "Cl", "Co", 
	"Cr", "Cs", "Cu", "F", "Fe", "Ga", "Gd", "Ge", "H", "Hf", "Hg", "I", "Ir", "K", "La", 
	"Li", "Mg", "Mo", "N", "Na", "Nb", "Nd", "Ni", "O", "Os", "P", "Pb", "Pd", "Pt", "Rb", 
	"Re", "Rh", "Ru", "S", "Sb", "Sc", "Se", "Si", "Sm", "Sr", "Ta", "Te", "Th", "Ti", 
	"Tl", "U", "V", "W", "Y", "Yb", "Zr"
]

# --- [3] 런타임 데이터 변수 ---
var minerals: Dictionary = {}

func _ready():
	load_database()

func load_database():
	var path = "res://assets/data/mineral_database.res"
	if FileAccess.file_exists(path):
		var db_res = load(path)
		minerals = db_res.get_meta("data")
		print("✅ 고증 광물 데이터베이스 로드 성공 (총 ", minerals.size(), "종)")
	else:
		print("⚠️ 데이터베이스 파일을 찾을 수 없습니다. 변환기를 먼저 실행하세요.")

# --- [4] 헬퍼 함수 ---

# 특정 좌표(행, 열)에 해당하는 원소 정보를 반환 (없으면 null)
func get_element_by_coord(r: int, c: int):
	for num in PERIODIC_TABLE_DATA:
		var data = PERIODIC_TABLE_DATA[num]
		if data.row == r and data.col == c:
			# 원자 번호(num)를 포함하여 반환
			var result = data.duplicate()
			result["number"] = num
			return result
	return null

# 이름으로 광물 검색
func get_mineral(mineral_name: String) -> MineralData:
	return minerals.get(mineral_name)

# 특정 원소가 포함된 광물 목록 찾기
func find_minerals_by_element(element_symbol: String) -> Array:
	var result = []
	for m in minerals.values():
		if m.elements.has(element_symbol):
			result.append(m)
	return result

# 해당 원소가 우리 시스템(66종)에 존재하는지 확인
func is_element_valid(symbol: String) -> bool:
	return symbol in VALID_ELEMENTS