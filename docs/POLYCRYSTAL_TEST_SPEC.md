# 다결정(Polycrystal / Cluster) 테스트 명세서 v0.1 (Godot)

단결정이 "프리즘+termination+chip+etch" 수준으로 안정화됐다는 전제에서, **다결정은 단결정 인스턴스를 여러 개 배치**하는 단계로 정의한다. (시간 성장 = 스케일만 커짐은 유지)

---

## 0. 목표

* 합성 시 1회 샘플링되는 **다결정 모델**을 생성한다.

* 다결정은 다음을 포함한다:
  * 결정 개수 N
  * 분포(어디에 붙는가)
  * 방향(정렬/퍼짐)
  * 공간 점유(부피감/겹침 정도)
  * 결합 강도(서로 얼마나 "붙어 보이는가")

* **테스트 씬**에서 F/C/K(+A) 파라미터를 조절하며 가시적으로 확인한다.

---

## 1. 용어 및 핵심 파라미터

### 1.1 단결정 파라미터 (이미 구현된 것)

* `sides, height, radius_top, radius_bottom, termination, chip, etch, seed, ...`
* 이 파라미터는 **"결정 1개 메시"**를 만든다.

### 1.2 다결정 파라미터 (새로 도입)

다결정은 아래 4개로 충분히 시작한다.

* **F = Fragmentation (파편화/개수·다양성)**
  * 높을수록: 결정 수 ↑, 크기 분산 ↑, 작은 결정 많아짐

* **C = Coherence (정렬/공동 방향성)**
  * 높을수록: 결정 축이 비슷한 방향으로 정렬(평행/방사형/부채형 포함 가능)

* **K = Compactness (집약/뭉침 정도)**
  * 높을수록: 더 조밀하게 붙음(겹침/침투 허용), 외곽이 둥글게 뭉친 덩어리 느낌

* **A = Anisotropy (공간 분포의 이방성/방사 패턴의 성향)**
  * 낮으면: 등방성(구형 덩어리)
  * 높으면: 한쪽으로 길게 뻗거나, 부채꼴/시트형/선형 클러스터 성향

> 주의: "부채꼴(팬)처럼 퍼지는 침상 다발"은 **C가 '평행'만 의미하면 못 나온다**.
> C는 "정렬 강도", A는 "정렬이 어떤 장(field) 형태로 작동하는지(방사/부채/선형)"까지 커버하도록 설계한다.

---

## 2. 다결정 생성 개요 (한 번만 샘플링)

* 합성 시 **DNA.seed**로 다결정 전체를 1번 샘플링
* 이후 시간 성장에서는 **Cluster 전체 transform scale만 변경**
* 즉, 다결정 구성(N, 배치, 방향, 결합 등)은 "고정"

---

## 3. 생성 파이프라인 (필수 단계)

### Step 1) "클러스터 스켈레톤" 정의

클러스터의 전체 형태를 결정하는 **붙는 자리(attachment points)**를 만든다.

* 기본 스켈레톤 타입 3개 (연속 확률로 혼합):
  1. **Mass (덩어리형)**: 중심 근처에 attachment 집중
  2. **Spray/Fan (부채꼴형)**: 한 축을 기준으로 각도가 벌어지는 방사 attachment
  3. **Chain/Vein (맥상/선형)**: 곡선/직선 라인 따라 attachment 생성

* 스켈레톤 선택은 혼합 비율:
  * `w_mass, w_fan, w_chain`을 A와 K로부터 연속적으로 산출
  * K↑ → mass 비중↑
  * A↑ → fan/chain 비중↑

### Step 2) 결정 개수 N 샘플링 (연속적 분포)

* 평균 개수 `μN = lerp(N_min, N_max, F)`
* 실제 N은 **포아송/네거티브 바이노미얼** 같은 카운트 분포에서 샘플:
  * 추천: `Poisson(μN)`
  * Godot에서는 직접 구현하거나 정규 근사+클램프 가능

* 권장 값:
  * `N_min = 3`
  * `N_max = 40` (테스트용)

### Step 3) 결정별 "크기 분포" 샘플링

* 결정 i의 스케일 `si`는 로그정규/감마 분포가 자연스럽다.
* F↑ → 분산↑, 작은 결정 다수
* K↑ → 큰 결정 비중↑(덩어리감)

* 권장:
  * `si = exp(normal(μ, σ(F)))` 형태
  * 또는 `pow(rng.randf(), bias)` 근사, `bias = lerp(0.6, 2.4, F)`

### Step 4) "방향(orientation)" 샘플링 (정렬 필드)

* **Coherence C**가 방향 분산 제어:
  * `θ ~ vonMisesFisher(κ(C))` 개념
  * `d = normalize(lerp(drand, d0, C))`

* **A(이방성)**가 `d0`가 어떤 장(field)인지 결정:
  * A 낮음: d0 = 랜덤(등방)
  * A 중간: d0 = 팬 방향(부채꼴)
  * A 높음: d0 = 체인 방향(한 축 정렬)

* 팬 형태:
  * attachment point가 중심에서 멀어질수록 방향 조금씩 달라지게
  * `d0(p) = normalize(fan_axis + fan_spread * tangent(p))`

### Step 5) 배치/충돌/결합(Compactness K)

* K 낮음: 충돌 회피 강하게 → 서로 떨어져 보임
* K 높음: 겹침 허용(침투), 일부는 매트릭스에 "박힌 느낌"(sink)

* 구현 정책(테스트 버전):
  * 최소거리: `min_dist = lerp(1.2, 0.4, K) * (si+sj)`
  * 실패 시 몇 번 재시도 후 그냥 배치

* 결합 강도 연출: 결합부 주변 보조 결정(secondary) 또는 매트릭스 mesh 추가

---

## 4. 매트릭스(Matrix) / 모암 처리

* 단결정만 여러 개 두면 "공중에 떠있는" 느낌 → **모암(매트릭스)** 최소 1개 생성

### 4.1 매트릭스 생성(테스트 버전)

* 단순: 거친 반구/덩어리 메쉬 1개 (노이즈 변형)
* K↑일수록 매트릭스 비중↑

### 4.2 결정의 sink(박힘)

* K와 결합 강도에 따라 결정 하단을 매트릭스 내부로 -Y 오프셋

---

## 5. 렌더링/머티리얼(테스트 스펙)

* 단결정: `StandardMaterial3D` 유지
* 다결정 클러스터:
  * **MultiMeshInstance3D 권장** (성능)
  * 단결정 메시 1~몇 개 공유, transform만 다르게 배치
  * chip/etch가 결정마다 다르면: 3~6종 메시 프리셋 + 그룹별 MultiMesh

---

## 6. DNA(저장 구조)

```json
{
  "seed": 123,
  "crystal_system": "hexagonal",
  "environment": {"temperature": 3, "pressure": "low", "pm": 33},
  "poly": {
    "F": 0.55,
    "C": 0.65,
    "K": 0.45,
    "A": 0.35,
    "count_hint": 18,
    "skeleton_mix": {"mass": 0.4, "fan": 0.4, "chain": 0.2}
  },
  "single": {
    "sides": 6,
    "height": 2.2,
    "radius_top": 0.45,
    "radius_bottom": 0.7,
    "termination": 0.8,
    "chip": 0.2,
    "etch": 0.1
  }
}
```

---

## 7. 테스트 씬 요구사항 (Poly 테스트)

### 7.1 씬 구성

* `PolyCrystalTest.tscn`
  * `Node3D` root
  * `Cluster (Node3D)`
    * `Matrix (MeshInstance3D)` (optional)
    * `Crystals` (MultiMeshInstance3D 또는 Node3D 아래 MeshInstance 여러 개)
  * `CameraRig` (기존 orbit_controller 재사용)
  * UI 슬라이더: seed, F, C, K, A, single 파라미터(sides, height, r_top, r_bot, termination)

### 7.2 디버그 표시(필수)

* 현재 N(결정 개수)
* skeleton mix 비율
* 평균/분산(스케일 분포)
* "재생성 시 카메라 자동 맞춤"(AABB fit) 옵션 토글

---

## 8. PM/온도/압력과의 연결(테스트 단계)

* PM을 **F/C/K/A의 prior(사전분포)**로만 사용
* 예시(초안):
  * 저온 수성/풍화(PM47): F↑, A↑, K↓
  * 페그마타이트(PM34): F↓, C↑, K 중간
  * 변성/고압: K↑, C↑

---

## 9. 구현 순서 (권장)

1. N 샘플링 + 스케일 분포 → 여러 개 뜨는지 확인
2. skeleton(attachment points) 추가
3. orientation field(C/A) 추가
4. compactness(K)로 충돌/침투/sink 조절
5. matrix 추가
6. MultiMesh 최적화(필요 시)

---

## 10. 성공 판정(테스트 체크리스트)

* F↑: 조각 많아짐/작아짐
* C↑: 방향 정렬↑ (A에 따라 평행/방사/부채)
* K↑: 더 뭉치고 결합부 자연스러움
* A↑: 한쪽/부채/선형으로 치우침
* seed 고정 시 완전 재현
* UI 이벤트 → orbit 전파 없음
* orthographic 전환 가능
