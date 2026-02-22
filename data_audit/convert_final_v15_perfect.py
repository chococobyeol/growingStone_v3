import csv
import json
import re
import os

# ==========================================
# 1. 2025 IUPAC 표준 원자량 사전 (1~118번 전 원소)
# 2024년 개정된 Zr, Gd, Lu 수치 및 2021 표준 반영
# ==========================================
ATOMIC_WEIGHTS = {
    'H': 1.008, 'He': 4.0026, 'Li': 6.94, 'Be': 9.0122, 'B': 10.81, 'C': 12.011, 'N': 14.007, 'O': 15.999,
    'F': 18.998, 'Ne': 20.180, 'Na': 22.990, 'Mg': 24.305, 'Al': 26.982, 'Si': 28.085, 'P': 30.974, 'S': 32.06,
    'Cl': 35.45, 'Ar': 39.948, 'K': 39.098, 'Ca': 40.078, 'Sc': 44.956, 'Ti': 47.867, 'V': 50.942, 'Cr': 51.996,
    'Mn': 54.938, 'Fe': 55.845, 'Co': 58.933, 'Ni': 58.693, 'Cu': 63.546, 'Zn': 65.38, 'Ga': 69.723, 'Ge': 72.63,
    'As': 74.922, 'Se': 78.971, 'Br': 79.904, 'Kr': 83.798, 'Rb': 85.468, 'Sr': 87.62, 'Y': 88.906, 'Zr': 91.224,
    'Nb': 92.906, 'Mo': 95.95, 'Tc': 98.0, 'Ru': 101.07, 'Rh': 102.91, 'Pd': 106.42, 'Ag': 107.87, 'Cd': 112.41,
    'In': 114.82, 'Sn': 118.71, 'Sb': 121.76, 'Te': 127.60, 'I': 126.90, 'Xe': 131.29, 'Cs': 132.91, 'Ba': 137.33,
    'La': 138.91, 'Ce': 140.12, 'Pr': 140.91, 'Nd': 144.24, 'Pm': 145.0, 'Sm': 150.36, 'Eu': 151.96, 'Gd': 157.25,
    'Tb': 158.93, 'Dy': 162.50, 'Ho': 164.93, 'Er': 167.26, 'Tm': 168.93, 'Yb': 173.05, 'Lu': 174.97, 'Hf': 178.49,
    'Ta': 180.95, 'W': 183.84, 'Re': 186.21, 'Os': 190.23, 'Ir': 192.22, 'Pt': 195.08, 'Au': 196.97, 'Hg': 200.59,
    'Tl': 204.38, 'Pb': 207.2, 'Bi': 208.98, 'Po': 209.0, 'At': 210.0, 'Rn': 222.0, 'Fr': 223.0, 'Ra': 226.0,
    'Ac': 227.0, 'Th': 232.04, 'Pa': 231.04, 'U': 238.03, 'Np': 237.0, 'Pu': 244.0, 'Am': 243.0, 'Cm': 247.0,
    'Bk': 247.0, 'Cf': 251.0, 'Es': 252.0, 'Fm': 257.0, 'Md': 258.0, 'No': 259.0, 'Lr': 262.0, 'Rf': 267.0,
    'Db': 270.0, 'Sg': 271.0, 'Bh': 270.0, 'Hs': 277.0, 'Mt': 278.0, 'Ds': 281.0, 'Rg': 282.0, 'Cn': 285.0,
    'Nh': 286.0, 'Fl': 289.0, 'Mc': 290.0, 'Lv': 293.0, 'Ts': 294.0, 'Og': 294.0
}

IDIOCHROMATIC_COLORS = {
    'Cu': '#00BFFF', 'Mn': '#FFB6C1', 'Ni': '#7FFF00', 'Co': '#4169E1',
    'Cr': '#228B22', 'U': '#ADFF2F', 'Fe': '#8B4513', 'S': '#FFFF00',
    'Au': '#FFD700', 'Ag': '#C0C0C0', 'As': '#808080', 'Sb': '#A9A9A9', 'Bi': '#D2B48C'
}

# PM별 광물 종 수 (Hazen & Morrison 2022, docs/PM_DISTRIBUTION.md)
PM_SPECIES_COUNT = {
    1: 22, 2: 1, 3: 48, 4: 47, 5: 94, 6: 205, 7: 123, 8: 93, 9: 127, 10: 107,
    11: 36, 12: 129, 13: 67, 14: 61, 15: 32, 16: 83, 17: 51, 18: 4, 19: 143,
    20: 45, 21: 79, 22: 247, 23: 398, 24: 74, 25: 210, 26: 250, 27: 9, 28: 10,
    29: 7, 30: 16, 31: 356, 32: 412, 33: 797, 34: 564, 35: 726, 36: 291, 37: 135,
    38: 108, 39: 70, 40: 319, 41: 16, 42: 15, 43: 9, 44: 11, 45: 424, 46: 52,
    47: 1998, 48: 71, 49: 77, 50: 273, 51: 128, 52: 72, 53: 117, 54: 234,
    55: 264, 56: 143, 57: 49
}

# PM별 지각 할당 파이 (Rudnick & Gao, docs/PM_DISTRIBUTION.md §3)
# 데이터 주도형: 확률 풀을 PM 종 수로 나눠 분배 → PM47 등 종 수 과다 PM의 확률 오염 차단
PM_PIE_ALLOCATIONS = {
    19: 0.50,  # 화강암질 심성암 (granite + granodiorite + tonalite)
    40: 0.30,  # 변성암 (gneiss, mica schist)
    8: 0.06,   # 고철질 화성암 (gabbro)
    23: 0.07,  # 표층 수변 변질 (sedimentary)
    47: 0.03,  # 저온 풍화 (수화물/H 과다 억제)
}
UNMAPPED_PM_PIE = 0.001  # 비지각 PM(열수·분기구 등)
# 미등록 희귀 원소(Hg, Pb, Au, Cu 등)의 타겟 원자수비. 0.01으로 설정해 게임 내 유의미한 출현 확보
RARE_ELEMENT_TARGET = 0.01

# 지각 원자수비(Atomic Fraction) 타겟 — Rudnick & Gao 질량비 → IUPAC 원자량으로 몰분율 환산
# Rudnick & Gao 2004 산화물 질량비 → IUPAC 원자량 몰분율 환산 (검증 반영)
TARGET_ATOMIC_PCT = {
    'O': 0.610, 'Si': 0.226, 'Al': 0.062, 'H': 0.029,
    'Na': 0.025, 'Ca': 0.013, 'Fe': 0.019, 'Mg': 0.013, 'K': 0.014,
    'Ti': 0.003, 'P': 0.001, 'Mn': 0.0005, 'F': 0.0005, 'S': 0.0002,
    # 위 외 원소는 RARE_ELEMENT_TARGET(0.01) 적용
}

# ==========================================
# 2. 로직 함수 (정밀 고증 시스템)
# ==========================================

def parse_pm_ids(paragenetic_modes_str):
    """Paragenetic Modes 문자열에서 PM 번호 목록 추출. 예: 'PM47 - ... PM50 - ...' -> [47, 50]"""
    if not paragenetic_modes_str or not isinstance(paragenetic_modes_str, str):
        return []
    pm_ids = []
    for m in re.findall(r'PM(\d+)', paragenetic_modes_str, re.IGNORECASE):
        n = int(m)
        if 1 <= n <= 57 and n not in pm_ids:
            pm_ids.append(n)
    return pm_ids

def compute_gacha_weight(pm_ids, elements):
    """데이터 주도형 가중치: PM 파이/종 수 분할 + 최소 희귀 원소 페널티.
    - 1단계: PM별 할당 파이를 해당 PM의 광물 종 수로 나눔 → PM47 등 종 수 과다 오염 차단
    - 2단계: 구성 원소 중 지각 원자수비가 가장 낮은 원소 기준 페널티 적용
    """
    # 1. base_weight: PM 파이 / 종 수 (광물이 여러 PM에 속하면 합산)
    base_weight = 0.0
    if not pm_ids:
        base_weight = 0.0001  # PM 미기재 = 희귀 가능성
    else:
        for pm in pm_ids:
            pm_pie = PM_PIE_ALLOCATIONS.get(pm, UNMAPPED_PM_PIE)
            species_count = PM_SPECIES_COUNT.get(pm, 1)
            base_weight += pm_pie / species_count

    # 2. 최소 희귀 원소 페널티 (Hg, Pb 등 포함 시 확률 기하급수 감소)
    min_element_target = 1.0
    for el in elements:
        t = TARGET_ATOMIC_PCT.get(el, RARE_ELEMENT_TARGET)
        if t < min_element_target:
            min_element_target = t

    final_weight = base_weight * min_element_target
    # 하한 1e-12: 1e-6이면 극소 가중치(1e-10 등)가 수백만 배 뻥튀기되어 희귀 금속 좀비화 발생
    return max(final_weight, 1e-12)  # PostgreSQL float8/numeric 정밀도 내, check(gacha_weight>0) 만족

def pm_ids_to_sql_array(pm_ids):
    """[47, 50] -> '{47,50}' (PostgreSQL int[] 리터럴)"""
    if not pm_ids:
        return '{}'
    return '{' + ','.join(str(p) for p in sorted(pm_ids)) + '}'

def is_pure_compound(formula):
    """철저한 고증: 고용체, 변수, 공석 배제.
    주의: 'n','z','y' 단일문자 검사는 Zn,Sn,In,Zr,Dy,Yb 등 원소기호와 충돌 → 변수 패턴만 매칭"""
    if ',' in formula or '☐' in formula or '≤' in formula:
        return False
    if re.search(r'\d+\.\d+', formula):
        return False
    # 변수 x (Xe는 대문자 X라 제외됨)
    if 'x' in formula:
        return False
    # 변수 n: ·nH2O 패턴만 (Zn,Sn,In 등 원소기호와 구분)
    if re.search(r'·\s*n\s*[H\d]', formula):
        return False
    return True

def parse_chemical_formula(formula):
    """v15 정밀 파서: 수화물 및 118종 전 원소 완벽 계산"""
    cleaned = re.sub(r'\d+[+-]', '', formula)
    cleaned = cleaned.replace('{', '(').replace('}', ')').replace('[', '(').replace(']', ')')
    tokens = re.findall(r'([A-Z][a-z]?|\d+\.?\d*|\(|\)|·)', cleaned)
    stack = [{}]
    i = 0
    seg_mult = 1.0 

    while i < len(tokens):
        t = tokens[i]
        if t == '(': stack.append({})
        elif t == ')':
            if len(stack) > 1:
                top = stack.pop(); mult = 1.0
                if i+1 < len(tokens) and re.match(r'^\d', tokens[i+1]):
                    mult = float(tokens[i+1]); i += 1
                for el, cnt in top.items():
                    stack[-1][el] = stack[-1].get(el, 0) + (cnt * mult * seg_mult)
        elif t == '·':
            seg_mult = 1.0 
            if i+1 < len(tokens) and re.match(r'^\d', tokens[i+1]):
                seg_mult = float(tokens[i+1]); i += 1
        elif t[0].isalpha():
            el = t; cnt = 1.0
            if i+1 < len(tokens) and re.match(r'^\d', tokens[i+1]):
                cnt = float(tokens[i+1]); i += 1
            if el in ATOMIC_WEIGHTS:
                stack[-1][el] = stack[-1].get(el, 0) + (cnt * seg_mult)
        i += 1
    return stack[0]

def predict_verified_color(elements, formula):
    if 'S' in elements and 'O' not in elements:
        if 'Fe' in elements: return '#DAA520'
        if 'Pb' in elements: return '#708090'
        if 'As' in elements: return '#FFD700'
        return '#A9A9A9'
    for el in IDIOCHROMATIC_COLORS:
        if el in elements and len(elements) <= 3:
            return IDIOCHROMATIC_COLORS[el]
    if 'Fe' in elements:
        return '#8B0000' if 'O' in elements and len(elements) <= 3 else '#556B2F'
    return '#FFFFFF' 

def generate_dna(crystal_sys, color):
    sys = crystal_sys.lower()
    is_transparent = 1 if color == '#FFFFFF' else 0
    props = {
        "system": sys, "scale": [1.0, 1.0, 1.0],
        "optical": {
            "transparent": is_transparent,
            "refraction": 1.5 if is_transparent else 0.0,
            "birefringence": 0.01 if sys != 'cubic' and is_transparent else 0.0
        }
    }
    if 'tetragonal' in sys: props["scale"] = [1.0, 1.0, 1.4]
    elif 'hexagonal' in sys or 'trigonal' in sys: props["scale"] = [1.0, 1.0, 1.6]
    elif 'orthorhombic' in sys: props["scale"] = [0.8, 1.0, 1.2]
    return json.dumps(props)

# ==========================================
# 3. 메인 실행 루틴 (경로 자동 인식 및 통계 리포트)
# ==========================================
def main():
    # 스크립트 파일의 현재 위치를 파악하여 경로 설정
    base_path = os.path.dirname(os.path.abspath(__file__))
    input_csv = os.path.join(base_path, 'ima_list.csv')
    output_sql = os.path.join(base_path, 'import_minerals_v16.sql')
    output_csv = os.path.join(base_path, 'minerals_audit_v16.csv')

    print(f"💎 [v16] 전 원소 표준 원자량 + PM/pm_ids/gacha_weight 변환 시작...")
    
    if not os.path.exists(input_csv):
        print(f"❌ 에러: 파일을 찾을 수 없습니다 -> {input_csv}")
        return

    sql_lines = ["TRUNCATE TABLE public.mineral_recipes RESTART IDENTITY CASCADE;"]
    csv_rows = []
    used_elements = set()
    count = 0
    
    with open(input_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            name, formula = row.get('Mineral Name (plain)', '').strip(), row.get('IMA Chemistry', '').strip()
            crystal = row.get('Crystal Systems', '').split(',')[0].strip()
            if not crystal:
                crystal = 'unknown'
            paragenetic_modes = row.get('Paragenetic Modes', '').strip()

            if not is_pure_compound(formula): continue

            elements = parse_chemical_formula(formula)
            if not elements: continue

            mass = 0.0
            for el, qty in elements.items():
                mass += ATOMIC_WEIGHTS[el] * qty
                used_elements.add(el)

            if mass == 0: continue

            pm_ids = parse_pm_ids(paragenetic_modes)
            gacha_weight = compute_gacha_weight(pm_ids, elements)
            gacha_weight = round(gacha_weight, 12)  # 1e-12 하한 보존 (8자리면 0으로 잘림)
            pm_ids_sql = pm_ids_to_sql_array(pm_ids)

            color_hex = predict_verified_color(elements, formula)
            dna_json = generate_dna(crystal, color_hex)
            elements_json = json.dumps({k: round(v, 2) for k, v in elements.items()})
            safe_name = name.replace("'", "''")

            sql = f"INSERT INTO public.mineral_recipes (name, formula, elements, base_density, base_color, dna, crystal_system, pm_ids, gacha_weight) VALUES ('{safe_name}', '{formula}', '{elements_json}', {round(mass, 4)}, '{color_hex}', '{dna_json}', '{crystal}', '{pm_ids_sql}', {gacha_weight});"
            sql_lines.append(sql)
            csv_rows.append({"name": name, "formula": formula, "elements": elements_json, "density": round(mass, 4), "color": color_hex, "crystal": crystal, "pm_ids": pm_ids_sql, "gacha_weight": gacha_weight})
            count += 1

    # 파일 저장
    with open(output_sql, 'w', encoding='utf-8') as f: f.write("\n".join(sql_lines))
    with open(output_csv, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=["name", "formula", "elements", "density", "color", "crystal", "pm_ids", "gacha_weight"])
        writer.writeheader(); writer.writerows(csv_rows)

    # 통계 리포트 출력
    print("\n" + "="*60)
    print(f"✨ v16 고증 변환 완료 리포트")
    print(f"- 순수 광물 데이터 수: {count}개")
    print(f"- 실제 사용된 원소 종류: {len(used_elements)}종")
    print(f"- 사용 원소 목록: {', '.join(sorted(list(used_elements)))}")
    print("="*60)
    print(f"📂 저장 완료: {output_sql}")

if __name__ == "__main__":
    main()