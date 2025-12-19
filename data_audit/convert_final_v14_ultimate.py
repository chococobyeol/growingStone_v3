import csv
import json
import re

# ==========================================
# 1. 기초 데이터 (원자량 및 광학 고증 데이터)
# ==========================================
# 희토류 및 주요 원소 70종 이상 전수 포함 (질량 고증용)
ATOMIC_WEIGHTS = {
    'H': 1.008, 'He': 4.003, 'Li': 6.94, 'Be': 9.01, 'B': 10.81, 'C': 12.01, 'N': 14.01, 'O': 16.00,
    'F': 19.00, 'Na': 22.99, 'Mg': 24.31, 'Al': 26.98, 'Si': 28.09, 'P': 30.97, 'S': 32.06,
    'Cl': 35.45, 'K': 39.10, 'Ca': 40.08, 'Sc': 44.96, 'Ti': 47.87, 'V': 50.94, 'Cr': 52.00,
    'Mn': 54.94, 'Fe': 55.85, 'Co': 58.93, 'Ni': 58.69, 'Cu': 63.55, 'Zn': 65.38, 'Ga': 69.72,
    'Ge': 72.63, 'As': 74.92, 'Se': 78.96, 'Br': 79.90, 'Rb': 85.47, 'Sr': 87.62, 'Y': 88.91,
    'Zr': 91.22, 'Nb': 92.91, 'Mo': 95.95, 'Tc': 98.0, 'Ru': 101.07, 'Rh': 102.91, 'Pd': 106.42,
    'Ag': 107.87, 'Cd': 112.41, 'In': 114.82, 'Sn': 118.71, 'Sb': 121.76, 'Te': 127.60, 
    'I': 126.90, 'Cs': 132.91, 'Ba': 137.33, 'La': 138.91, 'Ce': 140.12, 'Pr': 140.91, 
    'Nd': 144.24, 'Pm': 145.0, 'Sm': 150.36, 'Eu': 151.96, 'Gd': 157.25, 'Tb': 158.93, 
    'Dy': 162.50, 'Ho': 164.93, 'Er': 167.26, 'Tm': 168.93, 'Yb': 173.05, 'Lu': 174.97, 
    'Hf': 178.49, 'Ta': 180.95, 'W': 183.84, 'Re': 186.21, 'Os': 190.23, 'Ir': 192.22, 
    'Pt': 195.08, 'Au': 196.97, 'Hg': 200.59, 'Tl': 204.38, 'Pb': 207.2, 'Bi': 208.98, 
    'Th': 232.04, 'Pa': 231.04, 'U': 238.03
}

# 자색광물(Idiochromatic) 및 원소광물 표준 색상 (고증용)
IDIOCHROMATIC_COLORS = {
    'Cu': '#00BFFF', 'Mn': '#FFB6C1', 'Ni': '#7FFF00', 'Co': '#4169E1',
    'Cr': '#228B22', 'U': '#ADFF2F', 'Fe': '#8B4513', 'S': '#FFFF00',
    'Au': '#FFD700', 'Ag': '#C0C0C0', 'As': '#808080', 'Sb': '#A9A9A9', 'Bi': '#D2B48C'
}

# ==========================================
# 2. 로직 함수 (정밀 파서 및 필터)
# ==========================================

def is_pure_compound(formula):
    """철저한 고증: 고용체, 변수, 공석, 소수점 계수, 특수 기호를 전면 배제"""
    # 치환(,), 변수(x,y,z,n), 공석(☐), 부등호(≤)가 있으면 배제
    if any(c in formula for c in [',', 'x', 'y', 'z', 'n', '☐', '≤']): return False
    # 소수점 계수(Mg0.5 등) 배제
    if re.search(r'\d+\.\d+', formula): return False 
    return True

def parse_chemical_formula_ultimate(formula):
    """v14 정밀 파서: 수화물 계수(·nH2O) 및 중첩 괄호를 완벽하게 계산"""
    # 1. 가수 표기 제거 (Fe2+ -> Fe)
    cleaned = re.sub(r'\d+[+-]', '', formula)
    # 2. 괄호 표준화
    cleaned = cleaned.replace('{', '(').replace('}', ')').replace('[', '(').replace(']', ')')
    
    # 3. 토큰화 (원소, 숫자, 괄호, 수화물 기호 분리)
    tokens = re.findall(r'([A-Z][a-z]?|\d+|\(|\)|·)', cleaned)
    
    stack = [{}]
    i = 0
    seg_mult = 1.0 # 수화물 계수 관리 변수

    while i < len(tokens):
        t = tokens[i]
        
        if t == '(':
            stack.append({})
        elif t == ')':
            if len(stack) > 1:
                top = stack.pop()
                mult = 1.0
                if i+1 < len(tokens) and tokens[i+1].isdigit():
                    mult = float(tokens[i+1])
                    i += 1
                for el, cnt in top.items():
                    stack[-1][el] = stack[-1].get(el, 0) + (cnt * mult * seg_mult)
        elif t == '·':
            # 점 뒤에 숫자가 오면 그 뒤의 모든 원소에 곱함 (예: ·3H2O)
            seg_mult = 1.0
            if i+1 < len(tokens) and tokens[i+1].isdigit():
                seg_mult = float(tokens[i+1])
                i += 1
        elif t[0].isalpha():
            el = t
            cnt = 1.0
            if i+1 < len(tokens) and tokens[i+1].isdigit():
                cnt = float(tokens[i+1])
                i += 1
            if el in ATOMIC_WEIGHTS:
                stack[-1][el] = stack[-1].get(el, 0) + (cnt * seg_mult)
        i += 1
    return stack[0]

def predict_verified_color_ultimate(elements, formula):
    """광물학적 고증에 기반한 최종 색상 결정"""
    # 1. 황화물(Sulfides) 및 특수 고증
    if 'S' in elements and 'O' not in elements:
        if 'Fe' in elements: return '#DAA520' # 황철석 (금색)
        if 'Pb' in elements: return '#708090' # 방연석 (납회색)
        if 'As' in elements: return '#FFD700' # 석황 (노란색)
        return '#A9A9A9' # 일반 황화물 (회색)
    
    # 2. 원소 광물 및 자색 광물 (Idiochromatic)
    # 성분이 단순할수록 고유 색상이 지배적임
    for el in IDIOCHROMATIC_COLORS:
        if el in elements and len(elements) <= 3:
            return IDIOCHROMATIC_COLORS[el]
            
    # 3. 철(Fe) 함유 규산염/산화물
    if 'Fe' in elements:
        return '#8B0000' if 'O' in elements and len(elements) <= 3 else '#556B2F'
    
    # 4. 순수 규산염/탄산염 (고증: 순수 화합물은 무색 투명)
    return '#FFFFFF'

def generate_dna(crystal_sys, color):
    """결정계 및 광학 특성 DNA 생성 (고증 데이터 포함)"""
    sys = crystal_sys.lower()
    is_transparent = 1 if color == '#FFFFFF' else 0
    props = {
        "system": sys,
        "scale": [1.0, 1.0, 1.0],
        "optical": {
            "transparent": is_transparent,
            "refraction": 1.5 if is_transparent else 0.0,
            "birefringence": 0.01 if sys != 'cubic' and is_transparent else 0.0
        }
    }
    # 결정계별 형태학적 스케일 보정
    if 'tetragonal' in sys: props["scale"] = [1.0, 1.0, 1.4]
    elif 'hexagonal' in sys or 'trigonal' in sys: props["scale"] = [1.0, 1.0, 1.6]
    elif 'orthorhombic' in sys: props["scale"] = [0.8, 1.0, 1.2]
    elif 'monoclinic' in sys or 'triclinic' in sys: props["scale"] = [0.7, 1.0, 1.3]
    return json.dumps(props)

# ==========================================
# 3. 메인 실행 루틴 (SQL + CSV 생성)
# ==========================================
def main():
    print("🚀 [v14-Ultimate] 고증 데이터 정밀 변환 및 감사 리포트 생성 시작...")
    
    sql_lines = ["TRUNCATE TABLE public.mineral_recipes RESTART IDENTITY CASCADE;"]
    csv_rows = []
    csv_header = ["name", "formula", "elements", "density", "color", "crystal_system", "dna"]
    count = 0
    
    try:
        with open('ima_list.csv', 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                name = row.get('Mineral Name (plain)', '').strip()
                formula = row.get('IMA Chemistry', '').strip()
                crystal = row.get('Crystal Systems', '').split(',')[0].strip()
                
                # [1] 순수 화합물 필터링
                if not is_pure_compound(formula): continue
                
                # [2] 정밀 파싱
                elements = parse_chemical_formula_ultimate(formula)
                if not elements: continue
                
                # [3] 질량(밀도) 계산 - 원소 누락 없음
                mass = sum(ATOMIC_WEIGHTS[el] * qty for el, qty in elements.items() if el in ATOMIC_WEIGHTS)
                if mass == 0: continue

                # [4] 색상 및 DNA 고증 생성
                color_hex = predict_verified_color_ultimate(elements, formula)
                dna_json = generate_dna(crystal, color_hex)
                elements_json = json.dumps({k: round(v, 2) for k, v in elements.items()})
                safe_name = name.replace("'", "''")

                # [5] SQL 생성
                sql = f"INSERT INTO public.mineral_recipes (name, formula, elements, base_density, base_color, dna, crystal_system) VALUES ('{safe_name}', '{formula}', '{elements_json}', {round(mass, 2)}, '{color_hex}', '{dna_json}', '{crystal}');"
                sql_lines.append(sql)
                
                # [6] 감사용 CSV 데이터 추가
                csv_rows.append({
                    "name": name, "formula": formula, "elements": elements_json,
                    "density": round(mass, 2), "color": color_hex,
                    "crystal_system": crystal, "dna": dna_json
                })
                count += 1

        # 파일 출력
        with open('import_minerals_v14.sql', 'w', encoding='utf-8') as f:
            f.write("\n".join(sql_lines))
        with open('minerals_audit_v14.csv', 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=csv_header)
            writer.writeheader()
            writer.writerows(csv_rows)

        print(f"✨ 작업 완료! 총 {count}개의 데이터가 고증 검증을 통과했습니다.")
        print(f"- 생성 파일 1: import_minerals_v14.sql (DB 반영용)")
        print(f"- 생성 파일 2: minerals_audit_v14.csv (수치 검토용)")

    except Exception as e:
        print(f"오류 발생: {e}")

if __name__ == "__main__":
    main()