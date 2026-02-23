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
- [ ] 합성 RPC 또는 Edge Function (원소 차감, stones INSERT, 스톤 비용 차감)
- [ ] 원소 비율 → mineral_recipes 매칭 로직
- [ ] 합성 탭 UI 구현 (레시피 선택, 재료 확인, 실행)
- [ ] (선택) 미량 원소(발색소) UI

### 분해 (Decomposition)
- [ ] 분해 RPC (질량·성분비 기반 원소 환원, 질량에 따른 비용)
- [ ] 분해 탭 UI 구현

### 방치 성장·검증
- [ ] profiles 또는 세션 테이블에 last_access_at 추가
- [ ] 접속 시/종료 시 서버에 접속 시간 기록
- [ ] 성장 RPC: 서버 시간 기준으로 질량 계산 → stones.current_mass 갱신
- [ ] Stone.gd: 서버 질량 적용, 로컬 delta 제거

### 돌 렌더링
- [ ] Stone 노드에 recipe_id/base_color/dna 전달
- [ ] 셰이더에 광물 색상 반영
- [ ] (선택) 결정계 기반 절차적 형태

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
