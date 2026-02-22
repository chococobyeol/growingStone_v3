# PM(Paragenetic Mode)별 지구 분포 정리

**작성일:** 2026-02  
**목적:** 원소 뽑기 확률 산정용 PM 가중치 근거 문서

---

## 1. 자료 출처

### 1.1 PM-광물 종수 (Hazen & Morrison 2022)

- **논문:** *On the paragenetic modes of minerals: A mineral evolution perspective*  
  American Mineralogist, Vol. 107, pp. 1262–1287 (2022)  
  DOI: https://doi.org/10.2138/am-2022-8099
- **데이터:** IMA 공식 5,659종 광물에 대해 57개 PM별 종 수 집계
- **출처:** rruff.info/ima (2020년 11월 기준)

### 1.2 지각 암석 분포 (참고)

- **상부 대륙 지각** (Rudnick & Gao 등):
  - 화강암(granite): 25%
  - 편마암·운모편암(gneiss, mica schist): 30%
  - 화강섬록암(granodiorite): 20%
  - 퇴적암(sedimentary): 14%
  - 휘록암(gabbro): 6%
  - 토날라이트(tonalite): 5%

- **주요 조암 광물 부피 비율:**
  - 사장석: ~40%, 석영+알칼리장석: ~25%, 기타: ~37%

---

## 2. PM 전체 목록 및 종 수 (57개)

| PM# | Paragenetic Mode | No. species | 단계 |
|-----|------------------|-------------|------|
| 1 | Stellar atmosphere condensates | 22 | Pre-terrestrial |
| 2 | Interstellar condensates | 1 | Pre-terrestrial |
| 3 | Solar nebular condensates (CAIs, AOAs) | 48 | Stage 1 |
| 4 | Primary chondrule phases | 47 | Stage 1 |
| 5 | Primary asteroid phases | 94 | Stage 2 |
| 6 | Secondary asteroid phases | 205 | Stage 2 |
| 7 | Ultramafic igneous rocks | 123 | Stage 3a |
| 8 | Mafic igneous rocks | 93 | Stage 3a |
| 9 | Lava/xenolith minerals (hornfels, sanidinite) | 127 | Stage 3a |
| 10 | Basalt-hosted zeolite minerals | 107 | Stage 3a |
| 11 | Volcanic fumarole minerals (reduced) | 36 | Stage 3a |
| 12 | Hadean hydrothermal subsurface sulfide deposits | 129 | Stage 3b |
| 13 | Hadean serpentinization | 67 | Stage 3b |
| 14 | Hot springs, geysers, subaerial geothermal | 61 | Stage 3b |
| 15 | Black/white smoker, seafloor hydrothermal | 32 | Stage 3b |
| 16 | Low-T aqueous alteration of Hadean lithologies | 83 | Stage 3b |
| 17 | Marine authigenic Hadean minerals | 51 | Stage 3b |
| 18 | Minerals formed by freezing | 4 | Stage 3b |
| 19 | Granitic intrusive rocks | 143 | Stage 4a |
| 20 | Acidic volcanic rocks | 45 | Stage 4a |
| 21 | Chemically precipitated carbonate, phosphate, iron formations | 79 | Stage 4a |
| 22 | Hydration and low-T subsurface aqueous alteration | 247 | Stage 4a |
| 23 | Subaerial aqueous alteration (non-redox) | 398 | Stage 4a |
| 24 | Authigenic minerals in terrestrial sediments | 74 | Stage 4a |
| 25 | Evaporites (prebiotic) | 210 | Stage 4a |
| 26 | Hadean detrital minerals | 250 | Stage 4a |
| 27 | Radioactive decay; auto-oxidation | 9 | Stage 4a |
| 28 | Photo-alteration, pre-biotic | 10 | Stage 4a |
| 29 | Lightning-generated minerals | 7 | Stage 4a |
| 30 | Terrestrial impact minerals | 16 | Stage 4a |
| 31 | Thermally altered carbonate, phosphate, iron formations | 356 | Stage 4a |
| 32 | Ba/Mn/Pb/Zn deposits, metamorphic | 412 | Stage 4a |
| 33 | Hydrothermal metal-rich fluid deposition | 797 | Stage 4a |
| 34 | Complex granite pegmatites | 564 | Stage 4b |
| 35 | Ultra-alkali and agpaitic igneous rocks | 726 | Stage 4b |
| 36 | Carbonatites, kimberlites | 291 | Stage 4b |
| 37 | Layered igneous intrusions, PGE | 135 | Stage 4b |
| 38 | Ophiolites | 108 | Stage 5 |
| 39 | High-P metamorphism (blueschist, eclogite, UHP) | 70 | Stage 5 |
| 40 | Regional metamorphism (greenschist, amphibolite, granulite) | 319 | Stage 5 |
| 41 | Mantle metasomatism | 16 | Stage 5 |
| 42 | Sea-floor Mn nodules | 15 | Stage 5 |
| 43 | Shear-induced minerals | 9 | Stage 5 |
| 44 | Anoxic microbially mediated minerals | 11 | Stage 6 |
| 45 | Oxidized fumarolic minerals | 424 | Stage 7 |
| 46 | Near-surface hydrothermal alteration | 52 | Stage 7 |
| 47 | Low-T subaerial oxidative hydration, weathering | **1998** | Stage 7 |
| 48 | Soil leaching zone minerals | 71 | Stage 10a |
| 49 | Oxic cellular biomineralization | 77 | Stage 10a |
| 50 | Coal and/or oil shale minerals | 273 | Stage 10a |
| 51 | Pyrometamorphic minerals | 128 | Stage 10a |
| 52 | Guano- and urine-derived minerals | 72 | Stage 10a |
| 53 | Other minerals with taphonomic origins | 117 | Stage 10a |
| 54 | Coal and other mine fire minerals | 234 | Stage 10b |
| 55 | Anthropogenic mine minerals | 264 | Stage 10b |
| 56 | Slag and smelter minerals | 143 | Stage 10b |
| 57 | Other minerals formed by human processes | 49 | Stage 10b |

---

## 3. PM ↔ 지각 암석 유형 대응 (W_crust용)

| PM | 대응 암석/환경 | W_crust | 근거 (Rudnick & Gao 등) |
|----|----------------|---------|-------------------------|
| 19 | 화강암질 심성암 | 0.50 | 화강암 25% + 화강섬록암 20% + 토날라이트 5% |
| 40 | 변성암(편마암 등) | 0.30 | 편마암·운모편암 30% |
| 8 | 고철질 화성암 | 0.06 | 휘록암 6% |
| 23 | 표층 수변 변질 | 0.07 | 퇴적/풍화 14%의 일부 |
| 47 | 저온 풍화 | 0.03 | 기존 0.07→0.03 (수화물 과다로 H 비중 높음 방지) |
| 기타 PM | 비지각(열수·분기구 등) | 0.001 | 지각 부피 기여 무시, Hazen 2022 종 수만 소량 반영 |

### 3.1 Rudnick & Gao 2004 교차 검증 (지각 원자분율)

Rudnick & Gao 2004 (Treatise on Geochemistry) Table 1 "This Study" 상부 대륙 지각 산화물 질량비를 IUPAC 원자량으로 환산한 원자분율(at%):

| 원소 | 질량% | 원자분율(at%) |
|------|-------|---------------|
| O | ~47.5 | 60.7 |
| Si | ~31.1 | 23.0 |
| Al | ~8.2 | 6.4 |
| H | 0.14 | 2.9 |
| Fe, Ca, Na, K, Mg 등 | - | 1~2% |

HyperPhysics·Wikipedia 등과 일치(O 60~61%, Si 21~23%, Al 6~6.5%). 데이터 주도형 가중치(§4.2)가 이 비율에 수렴하도록 설계됨.

---

## 4. 가중치 산정 (데이터 주도형 Data-driven)

**채택:** 데이터 주도형 알고리즘. "1회 뽑기 총량 300(원자수)" 룰은 유지하고, **뽑기 확률(Gacha Weight)**만 제어하여 지각 원자수비에 수렴.

### 4.1 원인 분석: 기형적 원소 분포의 수학적 원인

1. **PM 종 수에 의한 확률 풀 오염**  
   PM47(1,998종)·PM33(797종) 등 풍화·열수 광물의 "머릿수"가 PM19(143종)·PM40(319종) 규산염을 압도 → O·H 과다, Si·Al 부족.

2. **질량비 vs 원자수비 괴리**  
   총량 300은 원자 개수 기준. H는 질량 0.14%지만 원자수 ~2.9%. Hg·Pb는 1번 뽑혀도 150원자 수급 → 극미량이어야 할 중금속 폭주.

### 4.2 데이터 주도형 알고리즘 (현행)

**[Step 1] PM 파이 / 종 수 분할 (확률 오염 차단)**

```
base_weight = Σ (pm_pie / species_count)  for each PM in pm_ids
```

- `pm_pie`: PM19→0.50, PM40→0.30, PM8→0.06, PM23→0.07, PM47→0.03, 기타→0.001
- PM47 광물 1종 = 0.03/1998 ≈ 0.000015 (기존 대비 극감)

**[Step 2] 최소 희귀 원소 페널티**

```
min_element_target = min( target_atomic_pct[el] for el in 광물 구성 원소 )
final_weight = base_weight × min_element_target
```

- `target_atomic_pct`: Rudnick & Gao 질량비 → IUPAC 원자량으로 환산한 원자수비 (O 61%, Si 22.6%, Al 6.2%, H 2.9% 등, §4.4 표)
- 희귀 원소(Hg, Pb, Au, Cu 등) 미등록 시 `RARE_ELEMENT_TARGET`(0.01) 적용 → 지각 극미량이지만 게임 내 유의미한 출현 확보

**[Step 3] 최종 저장**

- `gacha_weight = max(final_weight, 1e-12)`  
  - 하한 1e-6이면 극소 가중치가 수백만 배 뻥튀기되어 HgS·수화물 등이 "좀비"처럼 출현 → **1e-12**로 낮춰 과학적 계산값 유지

### 4.3 기대 효과

- **조암 광물 부상**: 석영·장석 등 Si·O 비율 높은 광물 → 페널티 적음 → 뽑기 80% 이상 규산염.
- **수소·수화물 억제**: PM47 1/1998 + H 타겟 0.029 페널티 → 수소 폭주 진압.
- **희귀 중금속 가치**: HgS·PbS·Au 광물 등 → RARE_ELEMENT_TARGET(0.01)로 유의미한 출현, 경매·수집 동기 부여.

### 4.4 target_atomic_pct (지각 원자수비, Rudnick & Gao 환산)

| 원소 | 원자분율 | 원소 | 원자분율 |
|------|----------|------|----------|
| O | 0.610 | Na | 0.025 |
| Si | 0.226 | Ca | 0.013 |
| Al | 0.062 | Fe | 0.019 |
| H | 0.029 | Mg | 0.013 |
| K | 0.014 | Ti | 0.003 |
| P | 0.001 | Mn | 0.0005 |
| F | 0.0005 | S | 0.0002 |

**미등록 원소**(Hg, Pb, Au, Cu, Ce 등): `RARE_ELEMENT_TARGET = 0.01` 적용.  
- 지질학적 극미량이지만, 게임 플레이(경매·수집 동기)를 위해 유의미하게 뽑히도록 조정.

### 4.5 PM 정보가 없는 경우 (pm_ids = {})

**원인:** `ima_list.csv`(rruff.info/ima) 원본에서 Paragenetic Modes 열이 비어 있는 경우.

**가중치:** `base_weight = 0.0001` 후, 구성 원소의 `min_element_target` 페널티 적용.  
- PM 미기재 = 희귀 가능성 → 최소 기반, 희귀 원소 포함 시 추가 감쇠.

---

## 5. ima_list.csv와의 매핑

- `ima_list.csv`의 Paragenetic Modes 열은 `PM47 - Low-T subaerial...` 형태.
- `PM47` → Hazen Table 1의 `#47`과 동일.
- 변환 시: `PM\d+` 정규식으로 PM 번호 추출 후, 위 가중치 표와 매칭.

---

## 6. 구현용 PM 가중치 표 (정규화)

종 수를 그대로 사용하거나, 확률 분포용으로 정규화:

```
총 종 수 합 ≈ 16,500 (57개 PM 합)
PM 가중치 = species_count / 16500  (대략)
```

**상위 10개 PM (가중치 높음):**

| PM | 이름 | 종 수 | 비고 |
|----|------|-------|------|
| 47 | Low-T oxidative weathering | 1998 | 가장 흔함 |
| 33 | Hydrothermal metal deposits | 797 | |
| 35 | Agpaitic rocks | 726 | |
| 34 | Granite pegmatites | 564 | |
| 45 | Oxidized fumarolic | 424 | |
| 32 | Ba/Mn/Pb/Zn deposits | 412 | |
| 23 | Subaerial aqueous alteration | 398 | |
| 31 | Thermally altered carbonate etc | 356 | |
| 40 | Regional metamorphism | 319 | |
| 36 | Carbonatites, kimberlites | 291 | |

**하위 5개 PM (가중치 낮음):**  
PM2(1), PM18(4), PM29(7), PM27(9), PM28(10)

---

## 7. 참고 문헌

- Hazen, R.M. & Morrison, S.M. (2022). On the paragenetic modes of minerals. *American Mineralogist* 107, 1262–1287.
- Rudnick, R.L. & Gao, S. (2014). Composition of the continental crust. *Treatise on Geochemistry* (2nd ed.).
- rruff.info/ima — IMA mineral list (PM 포함)
- mindat.org — 광물 산출 정보
