# GrowingStone v3 TODO

PRD 기준 1차 출시 및 이후 Phase별 작업 목록.

---

## Phase 1: 1차 출시 (최소 플레이 루프)

### 인증·프로필
- [x] 로그인/회원가입 (Auth.gd, AuthUI)
- [x] 프로필·초기 스톤 지급 (handle_new_user 트리거)
- [x] 프로필/돌 조회 (GameManager)

### 원소 뽑기
- [x] purchase_element_pack RPC (gacha_weight 기반)
- [x] 원소 뽑기 UI (LabUI)
- [x] 인벤토리·주기율표 표시

### 합성 (Synthesis)
- [x] 합성 RPC 또는 Edge Function (원소 차감, stones INSERT, 스톤 비용 차감)
- [x] 원소 비율 → mineral_recipes 매칭 로직
- [x] 합성 탭 UI 구현 (레시피 선택, 재료 확인, 실행)
- [ ] (선택) 미량 원소(발색소) UI

### 분해 (Decomposition)
- [ ] 분해 RPC (질량·성분비 기반 원소 환원, 질량에 따른 비용)
- [ ] 분해 탭 UI 구현

### 방치 성장·검증
- [ ] profiles 또는 세션 테이블에 last_access_at 추가
- [ ] 접속 시/종료 시 서버에 접속 시간 기록
- [ ] 성장 RPC: 서버 시간 기준으로 질량 계산 → stones.current_mass 갱신
- [ ] Stone(3D/stone_3d.gd): 서버 질량 적용, 로컬 delta 제거

### 돌 렌더링
- [x] Stone 노드에 recipe_id/base_color/dna 전달
- [x] 셰이더에 광물 색상 반영
- [x] (선택) 결정계 기반 절차적 형태 (IMA SDF, 전이금속 발색, 온도/압력, 2D 툰)

### 경제·밸런스
- [ ] 정기 스톤 지급 (일정 시간마다) 설계·구현

---

## Phase 2: 경매·소셜

### 블라인드 경매
- [ ] auctions, bids 테이블 및 RLS
- [ ] 판매 등록 RPC/UI
- [ ] 블라인드 입찰 RPC/UI
- [ ] 일괄 정산 (00:00 KST) Edge Function 또는 Cron

### 도감
- [ ] 도감 테이블 또는 뷰
- [ ] 도감 UI (수집 현황, 마일스톤)

### 돌 자랑 (공유·좋아요·주간 순위)
- [ ] shared_stones 등록 UI
- [ ] stone_likes·주간 랭킹 조회 UI
- [ ] 돌 데이터 기반 재렌더 표시

---

## 데이터·인프라

- [x] mineral_recipes 스키마 (dna, pm_ids, gacha_weight)
- [x] mineral_database.res (MineralDatabase 로드)
- [ ] v16 광물 데이터 Supabase 업로드 검증
- [ ] PM 분할·희귀 원소 페널티 purchase_element_pack 반영 확인

## 문서

- [x] 합성 구현 TODO 문서 작성 (`docs/SYNTHESIS_IMPLEMENTATION_TODO.md`)
- [x] 합성 UI 흐름 정렬 (주기율표 선택 → 리스트/비율 → 온도·압력 → 미량원소 → 합성)
- [x] 합성 탭 우선순위 개선 (주기율표 최상단/옵션 접기/탭 색상 가시성)
- [x] 합성 주기율표 UX 정렬 (원소 전체 노출 + 스크롤 접근, 선택 원소/조건 보기 시 주기율표 접힘)
- [x] 합성 선택 목록 순서/표시 일관화 (클릭 순서 유지, 주기율표 스케일·스타일 공통 함수화)
- [x] 합성 선택 패널 레이아웃 정렬 (좌측 리스트 확장, 우측 조건 컴팩트, 정수/슬라이더/백분율/소모량 표시)
- [x] 합성 패널 재구성 2차 (좌측 리스트 전용/우측 조건 박스 분리, 백분율 슬라이더 위치 체감 보정)
- [x] 합성 패널 재구성 3차 (오른쪽 3요소 분리: 온도·압력 박스 / + 버튼 / 합성 버튼, + 팝업 선택)
- [x] 합성 패널 정렬 보정 (좌측 폭 축소, 우측 컨트롤 세로/가로 중앙 정렬)
- [x] 탭 전환 상태 동기화 수정 (원소 뽑기/분해 탭에서 합성 UI, 팝업 강제 숨김)
- [x] 합성 우측 레이아웃 스케치 반영 (온도/압력/미량원소 세로 박스 + 하단 합성 버튼)
- [x] 비율 슬라이더 드래그 개선 (드래그 중 미리보기, 드래그 종료 시 재렌더링 반영)
- [x] 온도/압력 입력 UI 고도화 (온도 5분할 세그먼트, 압력 저압/고압 토글 버튼)
- [x] 미량원소 입력 UI 고도화 (모달에서 원소+농도(1~3) 선택, 박스 내 칩 표시/삭제)
- [x] 미량원소 검증 강화 (원소 중복 금지, 최대 3종, 보유량 체크, 합성 RPC trace_elements 전달)
