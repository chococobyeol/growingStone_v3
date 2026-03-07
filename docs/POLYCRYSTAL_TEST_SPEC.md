# 다결정(PolyCrystal) 테스트/생성기 설계 명세

단결정(CrystalGenerator)이 안정화된 전제에서, **다결정은 단결정 인스턴스를 여러 개 배치**하고 **모암(Matrix)** 를 함께 렌더링하는 단계로 정의한다.

아래 **v2** 는 **불규칙 블롭(폐곡면) 매트릭스** 적용 및 **결정 접지(grounding)** 를 전제로 한 수정 설계 명세이다. 코드 수정 시 이 명세를 기준으로 구현한다.

---

# PolyCrystal v2 설계 명세 (Matrix=Irregular Blob, Closed Mesh)

## 0. 목표

* 다결정 클러스터에서 “모암/매트릭스”가 **반구(아래 뻥뚫림)**가 아니라,
  * **아래까지 막힌 폐곡면(Closed manifold)** 형태의 **불규칙 블롭**으로 렌더링되도록 한다.
* 카메라가 아래를 보더라도 내부가 보이지 않도록 한다.
* 결정들이 공중에 뜨는 현상을 줄이고, 최소한 “모암 표면에 박힌” 느낌이 나도록 한다.

---

## 1. 씬/노드 구성

### 1.1 Cluster 아래 자식 노드

`Cluster (Node3D)` 하위에 아래가 생성된다.

1. **Matrix (MeshInstance3D)**
   * 불규칙 블롭 메시(폐곡면) + 불투명 재질(rough, matte)
   * 원점 기준 대략 `y=0` 근방에 위치하도록 생성하되, **하단이 y<0까지 내려가도록** 만들어 “바닥이 있음”이 보이게 한다.

2. **Crystals_i (MultiMeshInstance3D)** 여러 개
   * preset_count 만큼.
   * 결정은 모두 **Matrix 위/안에 박힌 것처럼** 위치 보정(sink / clamp)을 적용한다.

---

## 2. 파라미터 스키마 변경

### 2.1 poly_crystal_generator.gd default_params 추가/수정

기존:

* `matrix_enabled`, `matrix_scale` 유지

추가(권장):

```gdscript
"matrix": {
  "shape": "blob",            # 고정값(향후 확장)
  "radius": 1.2,              # 블롭 기본 반경 (matrix_scale과 곱해도 됨)
  "radial_seg": 24,           # 둘레 분할
  "rings": 16,                # 위/아래 링 수
  "noise_amp": 0.18,          # 표면 변형 강도 (0..0.4)
  "noise_freq": 1.0,          # 변형 주파수 (저주파 위주)
  "anisotropy": Vector3(1.35, 0.85, 1.15),  # 타원체 스케일
  "bottom_bias": 0.35,        # 아래쪽을 더 두껍게 (0..1)
  "seed_offset": 7717
},
"placement": {
  "grounding_mode": "clamp_to_matrix",  # "simple_sink" | "clamp_to_matrix"
  "sink_strength": 0.20,                # 박힘 정도 (0..0.6)
  "float_guard": 0.05                   # 공중 뜸 방지 여유
}
```

UI에는 당장 노출 안 해도 됨(내부 튜닝용).

---

## 3. Matrix(불규칙 블롭) 메시 생성 규격

### 3.1 메시 요구사항

* **닫힌 메시(Closed)**: 위/아래 모두 막혀 있어야 함.
* 노멀 일관성: **모두 바깥 방향**.
* 자기 교차 최소화: 변형 강도를 제한하고, 극점(pole) 부근이 찌그러져 뒤집히지 않게 한다.
* 규칙적 구형/반구형을 피한다:
  * 기본을 “타원체(Anisotropy)”로 만들고,
  * 저주파 노이즈로 실루엣을 변형한다.
* 바닥은 완전 평평하면 인공적이므로:
  * 아래쪽도 완만히 둥글거나,
  * `bottom_bias`로 **아래가 더 두꺼운** 덩어리 형태를 만든다.

### 3.2 생성 방식(권장: Parametric sphere 기반 폐곡면)

1. 기본 구/타원체 surface를 parametric으로 생성
   * `phi: 0..PI`, `theta: 0..TAU`
2. 각 vertex에 대해:
   * 기본 반지름 `R`
   * 타원 스케일 적용: `(x*ax, y*ay, z*az)`
   * 노이즈 변형: `R' = R * (1 + noise_amp * low_freq_noise(phi, theta, seed))`
   * bottom_bias 적용: `y<0` 영역에서 R’ 또는 y를 추가로 눌러 “덩어리” 느낌 강화
3. 인덱스 삼각형으로 surface 구성(Indexed mesh 가능)
4. 노멀 재계산(또는 vertex 위치 기반 normalize)
5. 필요 시:
   * 지나친 변형으로 노멀이 뒤집히는 케이스를 감지/클램프(amp 제한)

※ “반구+바닥 캡”도 폐곡면은 되지만 실루엣이 여전히 반구 느낌이라 권장하지 않음.

---

## 4. 결정 배치/접지(떠있음 방지) 규격

### 4.1 문제 정의

현재 배치는 3D 공간에 포인트를 찍고 `sink`만 조금 적용해서,

* 매트릭스 내부/외부 판정이 없어 “공중 부양”이 생길 수 있음.

### 4.2 grounding_mode

#### A) simple_sink (간단/빠름)

* 기존처럼 pos.y를 sink로 내리되,
* `float_guard`만큼 추가로 내려서 “떠있음”을 최소화.
* 장점: 구현 쉬움, 성능 좋음
* 단점: 매트릭스와 실제 접촉 느낌은 약함

#### B) clamp_to_matrix (권장)

Matrix가 “대략 타원체+노이즈”로 생성되므로,

* 같은 함수(또는 근사)로 **주어진 xz에서 표면 y를 추정**하거나,
* 더 일반적으로는 `pos` 방향의 레이/투영 기반으로 표면 교점을 구한다.

권장 구현(근사, 성능형):

* matrix가 “원점 중심 블롭”이면,
  * `dir = normalize(Vector3(x, 0, z))` 또는 `normalize(pos)` 기반으로
  * 해당 방향에서의 표면 반지름 `r_surface(dir)`를 같은 노이즈 함수로 계산 가능
  * pos를 `pos = dir * r_surface(dir) + offset` 형태로 표면으로 끌어당김
  * y는 `-sink_strength * scale` 만큼 추가로 내려 박힘 연출

요구 결과:

* 결정 바닥이 최소한 모암 내부로 약간 들어가 보이고,
* 공중에 따로 떠 보이는 개체가 거의 없어야 한다.

---

## 5. 머티리얼/렌더링 규격

### 5.1 Matrix material (불투명 권장)

* `opacity = 1.0` 고정(투명 금지)
* roughness 높게(0.85~0.98)
* metallic 0
* 단색 + 약간의 색 랜덤 가능(시드 기반)

### 5.2 Crystal material

* 투명/반투명 유지 가능하나,
* 다결정 테스트에서 “면이 안 보인다/깜빡인다” 류 문제가 있으면
  * 테스트 단계에서는 `opacity=1.0`로 강제해 디버깅을 우선한다.
  * (투명은 depth sorting 이슈가 생길 수 있음)

---

## 6. 검증 체크리스트 (완료 조건)

1. 카메라를 아래로 돌려도 Matrix 내부가 보이지 않는다(바닥 뻥 없음).
2. Matrix 실루엣이 “구/반구”처럼 규칙적이지 않고, 덩어리 느낌이 난다.
3. 결정들이 공중에 떠 보이는 케이스가 극히 드물거나 없어야 한다.
4. seed 고정 시:
   * Matrix 형태, 결정 배치/회전/스케일이 재현된다(PRNG 결정적).

---

## 7. PRNG/재현성 규칙

* Poly seed 하나로 아래가 모두 결정되어야 함:
  * N(개수), 분포 타입 샘플링, 스케일, 위치, 방향, preset seed, matrix blob 노이즈
* `seed_offset` 같은 상수는 **명세로 고정**하고, 코드에서 임의 변경하지 않는다.

---

# 참고: 다결정 파라미터 F/C/K/A 및 파이프라인 (v0.1)

## 용어 및 핵심 파라미터

### 단결정 파라미터 (CrystalGenerator)

* `sides, height, radius_top, radius_bottom, termination, chip, etch, seed, ...`

### 다결정 파라미터 F/C/K/A

* **F = Fragmentation (파편화/개수·다양성)**  
  높을수록: 결정 수 ↑, 크기 분산 ↑, 작은 결정 많아짐

* **C = Coherence (정렬/공동 방향성)**  
  높을수록: 결정 축이 비슷한 방향으로 정렬(평행/방사형/부채형)

* **K = Compactness (집약/뭉침 정도)**  
  높을수록: 더 조밀하게 붙음(겹침/침투 허용), 덩어리 느낌

* **A = Anisotropy (공간 분포의 이방성)**  
  낮으면: 등방성(구형 덩어리) / 높으면: 부채꼴/시트형/선형 클러스터 성향

## 생성 파이프라인 요약

1. 클러스터 스켈레톤: Mass / Fan / Chain 혼합 비율(w_mass, w_fan, w_chain)
2. N 샘플링: Poisson(μN), N_min..N_max
3. 스케일 분포: F/K에 따른 분산
4. 방향(orientation): C/A에 따른 정렬 필드
5. 배치/충돌: K에 따른 spacing, sink, (v2: grounding_mode)

## 테스트 씬 구성 (Poly 테스트)

* `test_poly_crystal.tscn`
  * `Node3D` root → `Cluster (Node3D)` → Matrix + Crystals_0..k (MultiMeshInstance3D)
  * `CameraRig` (orbit_controller)
  * UI: seed, F, C, K, A, single(sides, height, r_top, r_bot, termination 등)

## DNA/저장 구조 (참고)

```json
{
  "seed": 123,
  "poly": { "F": 0.55, "C": 0.65, "K": 0.45, "A": 0.35, "count_hint": 18 },
  "single": { "sides": 6, "height": 2.2, "radius_top": 0.45, "radius_bottom": 0.7, "termination": 0.8, "chip": 0.2, "etch": 0.1 }
}
```

---

**다음 단계(코드 수정)** 에서는:

* `_build_matrix_mesh()`를 위 명세대로 “폐곡면 블롭” 생성기로 교체
* `clamp_to_matrix` 기반 접지 로직 추가
* (옵션) 단결정 캡이 너무 평평한 문제 해결(거친 바닥 캡 등)까지 묶어서 적용 가능
