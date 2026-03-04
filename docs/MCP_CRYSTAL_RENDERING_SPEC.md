# MCP 작업 명세서: growingStone 렌더링(단결정) Godot 4 이식

> **용도:** Godot MCP(코덱스/에이전트)에게 그대로 붙여넣을 **실행 명세서**  
> **목표:** 웹에서 검증한 indexed 토폴로지 + termination facet + chip/etch + hard edge를 Godot 4에서 동일하게 재현하고, 다결정 확장/게임 파이프라인까지 연결 가능하게 만든다.

---

## 0) 작업 목표/범위

### 최종 목표

Godot 4 프로젝트에서 **절차 생성 단결정(1 crystal)** 메시를 런타임에 생성하고, 다음을 만족한다.

1. **토폴로지 seam/틈 없음**
   * side와 termination 영역이 **정점/인덱스를 공유하는 indexed mesh** 구조여야 한다.
   * CylinderMesh/PrimitiveMesh 기반이 아니라, **직접 버텍스/인덱스 생성**으로 구현한다.

2. **종단(termination)이 평평한 캡이 아니라 facet로 끝남**
   * top cap을 쓰지 말고,
   * `top ring -> crown ring -> center`로 이어지는 **termination facets**로 구성한다.

3. **chip / etch 변형이 가능**
   * chip: 종단 일부가 깨져나간 듯한 형태(국소적으로 inward + downward)
   * etch: 미세한 표면 불규칙(작은 노이즈 기반 변형)
   * 변형은 **정점 공유를 깨지 않으면서** 적용한다.

4. **하드 엣지("고구마 스무딩" 방지)**
   * 면이 각져 보이도록 하드 엣지를 유지한다.
   * Godot에서 "creaseAngle"에 의해 하드 엣지 강도를 조절 가능해야 한다.
   * 구현 방식은 자유(정점 분리/노멀 계산 등)지만 결과가 하드 페이스로 보이면 된다.

### 범위

* 1차 목표: **단결정** 생성기 + 테스트 씬/GUI
* 다결정(클러스터) 생성은 **후속 작업** (이번 명세에는 확장 포인트만 포함)

---

## 1) 기술 스택/제약

* **Godot 4.x** 기준
* GDScript로 구현(필요시 C# 제안 가능하나 기본은 GDScript)
* 메시 생성: `ArrayMesh` 권장
* 노멀/탠젠트:
  * 기본은 버텍스 노멀 제공
  * 하드 엣지 구현을 위해 정점 분리(duplicate) 가능
* 외부 애셋/플러그인 의존 금지
* 난수: Godot 내장 RNG에 의존하지 말 것(엔진 변경 시 결과 달라질 수 있음)
  * 자체 PRNG 구현(예: xorshift32/PCG)로 **seed 고정 시 동일 결과** 보장

---

## 2) 산출물(파일) 요구사항

### 필수 파일 1) `res://scripts/prng.gd`

* 고정 PRNG 구현
* 입력 seed(int) → `randf()` [0,1) 제공
* `rand_range(a,b)` / `randi_range(a,b)` 유틸 포함

### 필수 파일 2) `res://scripts/crystal_generator.gd`

단결정 생성기 클래스. 아래 API를 제공.

#### API

* `func build_single_crystal(params: Dictionary) -> ArrayMesh`
* `func build_single_crystal_arrays(params: Dictionary) -> Dictionary`
  * 디버깅 목적: vertices/indices/normals/uvs 반환

#### params 스키마(필수 키)

* `seed: int`
* `sides: int` (3~12)
* `height: float`
* `radius_top: float`
* `radius_bottom: float`

Termination 그룹:

* `termination: float` (0..1)
* `termination_height: float` (0.05..0.95) * height
* `termination_region: float` (0.02..0.6)
* `asymmetry: float` (0..1)

Surface 그룹:

* `chip: float` (0..1)
* `etch: float` (0..1)
* `crease_angle_deg: float` (1..89)

추가(렌더용):

* `base_color: Color`
* `opacity: float` (0.15..1)

### 필수 파일 3) `res://scenes/test_crystal.tscn`

테스트 씬: 화면에 단결정 1개를 띄우고 파라미터 조정 가능

요구 구성:

* `Node3D` 루트
* `Camera3D`
* `DirectionalLight3D` 2개(+ `WorldEnvironment` 옵션)
* `MeshInstance3D` 1개 (생성된 ArrayMesh 적용)
* `CanvasLayer` + `UI`(최소한의 슬라이더/입력)
  * seed, sides, height, radius, termination, chip, etch, crease_angle 조절
  * 값 변경 시 재생성
* 마우스 드래그로 회전 / 휠로 줌(간단한 orbit 컨트롤 스크립트 포함)

### 선택 파일) `res://scripts/orbit_controller.gd`

* 간단 orbit 컨트롤
* 또는 Godot 기본 Input 이벤트로 처리

---

## 3) 메시 토폴로지 명세(핵심)

### 버텍스 레이아웃(권장)

정점은 "링" 단위로 생성하며, 기본은 indexed 구조를 유지한다.

* bottom ring: `sides`개
* top ring: `sides`개 (side와 termination이 공유하는 링)
* crown ring: `sides`개 (termination facet용, top ring 안쪽/위쪽)
* crown center: 1개

총 정점 수: `3*sides + 1` (하드 엣지 구현에 따라 증가 가능)

### 인덱스 구성(삼각형)

1. **Side faces (프리즘 측면)**
   * 각 i에 대해 quad를 2 tri로
   * (b0, t0, t1), (b0, t1, b1)

2. **Termination frustum faces (top ring -> crown ring)**
   * 각 i에 대해
   * (t0, c0, c1), (t0, c1, t1)

3. **Crown to center (crown ring -> center)**
   * 각 i에 대해
   * (c0, center, c1)

**중요:**

* **flat cap은 만들지 않는다.**
* top ring이 side와 termination에서 **같은 정점 인덱스**여야 seam이 사라진다.

---

## 4) 형상 생성/변형 알고리즘 명세

### 4.1 기본 링 생성

* 각 i에 대해 angle = 2π * i/sides
* bottom[i] = (cos*a * radius_bottom, 0, sin*a * radius_bottom)
* top[i] = (cos*a * radius_top, height, sin*a * radius_top)

### 4.2 Termination shaping (top ring 변형)

목표: top ring 자체를 변형해서 "평평한 캡"이 되지 않게 만든다.

필수 요소:

* bias direction(수평) 하나 생성 (seed 기반)
* 각 top ring 정점에 대해:
  * bias와의 내적/각도에 따른 region factor 계산
  * `termination`과 `asymmetry`, `termination_region`으로 영향을 조절
  * y를 `termination_height*height` 이상으로 떨어뜨리지 않도록 clamp
  * x,z는 inward scale(수축) 적용

노이즈:

* 빠른 pseudo noise(사인 합 등) 사용 가능
* seed와 i를 섞어서 결정적 값 생성

### 4.3 Crown ring 생성

* crown[i]는 top[i]에서 inward + upward 한 위치
* inward 정도는 termination에 비례
* crownLift(위로 올림)도 termination에 비례
* crown center는 crown 평균 + 약간의 비대칭 오프셋

### 4.4 Chip 변형(국소 깨짐)

* 종단 영역(termination 근방)에서만 적용
* 랜덤한 "chip plane"을 만들고, plane 한쪽에 속하는 정점만 변형
* 변형 방향: radial inward + 약간 downward
* 강도: `chip` * (정점이 top에 가까울수록 더 강함)

### 4.5 Etch 변형(미세 표면 불규칙)

* 모든 정점 또는 top 위주로 적용 가능
* 작은 amplitude로 radial 방향 변위 + 약간 y 변위
* 강도: `etch` * w(top bias)

### 4.6 노멀/하드엣지(creaseAngle)

목표: 면이 "각져" 보이게 한다.

허용 구현(둘 중 하나 이상):

* **방식 A:** creaseAngle 기준으로, edge가 sharp하면 정점을 분리해 노멀을 분리(flat-like)
* **방식 B:** 모든 면을 flat shading에 가깝게(각 face의 노멀) 처리
* **방식 C:** side는 crease, termination은 더 강하게 crease 등 영역별 처리

중요:

* 결과가 스무딩되어 둥글게 보이면 실패
* creaseAngle이 작을수록 더 각지고, 클수록 더 부드러워지는 동작을 구현

---

## 5) UV/재질(최소)

* UV는 디버그 수준이면 충분
* 권장: 원통 투영 형태
  * u = atan2(z,x)/2π + 0.5
  * v = 링 종류별로 0(bottom), 0.75(top), 0.95(crown), 1(center)

재질은 테스트용으로:

* `StandardMaterial3D`
* base_color/roughness 설정
* opacity<1이면 transparency on

---

## 6) 검증(테스트) 요구사항

테스트 씬에서 아래 케이스를 확인할 수 있어야 한다.

1. **틈이 보이지 않는다**
   * 카메라를 termination 근처에 근접해서 회전해도 면 사이가 벌어져 보이면 실패

2. **끝이 평평한 캡이 아니다**
   * termination=0.7~1.0에서 종단이 facet로 보이며 뾰족/불규칙함이 나타나야 한다.

3. **chip/etch가 시각적으로 반영된다**
   * chip 0 -> 0.8 변화 시 "깨짐"이 확실히 증가
   * etch 0 -> 0.8 변화 시 표면 미세 흔들림 증가(너무 과하면 실루엣 붕괴, 적당히)

4. **하드 엣지**
   * creaseAngle 15~30에서 크리스탈 면이 각져 보인다.
   * creaseAngle 60~80에서 상대적으로 부드러워진다.

5. **시드 고정 안정성**
   * seed 고정 시 재생성해도 동일 메시가 나온다(정점/인덱스 동일)

---

## 7) 성능/확장 포인트(다결정 대비)

이번 단계는 단결정이지만, 다음 확장을 고려해 구조를 준비한다.

* `build_single_crystal_arrays()`가 배열을 반환하면,
  * 다결정 생성 시 같은 함수로 여러 개 생성 후 transform만 적용 가능
* seed 파생 규칙:
  * cluster seed에서 child seed를 결정적으로 생성(예: seed ^ (i*constant))

다결정에서 필요한 파라미터(F/C/K)는 이후 추가하되, 이번 단결정 파라미터와 충돌하지 않게 네이밍을 유지한다.

---

## 8) 작업 순서(에이전트 실행 계획)

1. PRNG 구현 파일 생성
2. crystal_generator.gd 구현
   * 링 생성 -> termination -> crown -> 인덱스 -> chip/etch -> 노멀
3. test_crystal.tscn + 컨트롤 UI 구성
4. seam/하드엣지/termination 검증 후 버그 수정
5. 코드 정리/주석/파라미터 범위 고정

---

## 9) 완료 기준(Definition of Done)

* Godot에서 실행 시, 단결정 메시가 화면에 나타나고 UI 조절이 즉시 반영된다.
* termination 부분에 "검은 틈/벌어짐/단차"가 재현되지 않는다.
* "고구마 스무딩"이 아니라 크리스탈 면이 각져 보인다.
* seed 고정 시 형태가 결정적으로 유지된다.
