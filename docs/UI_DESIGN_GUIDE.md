# GrowingStone UI Design Guide (v2 - implementation strict)

## 1) 목적
- 구현 중 해석 차이로 재작업이 발생하지 않도록, 로그인 UI 규격을 고정한다.
- 이 문서는 "가이드"가 아니라 "실행 스펙"으로 사용한다.

## 2) 우선순위 규칙
- `MUST`: 반드시 지켜야 함. 변경 시 사전 합의 필요.
- `SHOULD`: 권장. 상황상 불가할 때만 예외 허용.
- `MUST NOT`: 금지.

## 3) 고정 토큰 (MUST)

### 색상
- `bg/card`: `#F2F2F2`
- `text/primary`: `#1F1F1F`
- `text/secondary`: `#555555`
- `brand/primary`: `#ACD8B9`
- `brand/primary_hover`: `#9FCFAA`
- `brand/primary_pressed`: `#8FC39A`
- `state/error`: `#D9534F`
- `state/success`: `#2E7D32`

### 타이포그래피 매핑
- `title`: `온글잎 의연체.ttf` (MUST)
- `subtitle`: `IM_Hyemin-Regular.otf` (MUST)
- `input/button/status/lang`: `IM_Hyemin-Regular.otf` (MUST)

### 폰트 크기 기준
- `title`: 56 (SHOULD: 52~60)
- `subtitle`: 20 (SHOULD: 18~22)
- `input/button/lang`: 24 (SHOULD: 20~24)
- `status`: 18 (SHOULD: 16~18)

## 4) 로그인 화면 구조 (MUST)
- 루트: `Control`
- 중앙 정렬: `CenterContainer`
- 카드: `PanelContainer` (`custom_minimum_size`: `820x560`)
- 카드 내부: `MarginContainer` + `VBoxContainer`
- 필수 컴포넌트 순서:
  1. Title
  2. Subtitle
  3. Email
  4. Password
  5. Login
  6. SignUp
  7. Status
  8. Language row
  9. Close button (카드 외곽 코너 겹침)

## 5) Close(X) 버튼 스펙 (MUST)
- 형태: 원형 버튼
- 배치: 카드 우상단 코너에 "겹치게" 배치
- 아이콘: 텍스트 `X` 금지, 벡터 도형/아이콘 사용
- 색상: 중립 회색 계열만 사용
- 크기: 버튼 40x40
- 동작: 클릭 시 앱 종료 (`get_tree().quit()`)

## 6) 상태/행동 스펙 (MUST)
- `idle`: status 비움
- `loading`: 로그인/회원가입 버튼 비활성
- `success`: 성공 메시지 후 `Main.tscn` 이동
- `error`: 서버 메시지 우선 노출
- 이메일 입력값은 `trim + lowercase` 처리

## 7) 창/레이아웃 규칙 (MUST)
- 로그인 시작 시 "첫 프레임 쏠림" 발생하면 안 됨
- 런타임에서 창 크기/모드 반복 변경 금지
- 컨테이너 기반 배치 유지 (`CenterContainer`, `VBoxContainer`)

## 8) 변경 금지 항목 (MUST NOT)
- 사용자 요청 없이 메인 색상 팔레트 변경 금지
- 사용자 요청 없이 폰트 매핑 변경 금지
- 사용자 요청 없이 배경 추가/제거 금지
- 사용자 요청 없이 버튼 위치 규칙 변경 금지

## 9) 수용 기준 (Acceptance Criteria)
- 첫 실행에서 UI 쏠림/깨짐 없음
- `X` 버튼이 카드 우상단 코너에 시각적으로 겹쳐 보임
- `X`는 텍스트가 아닌 벡터 아이콘으로 표시됨
- 타이틀은 온글잎 의연체, 나머지는 iM 혜민체
- 로그인/회원가입/에러 상태가 색/문구로 구분됨
- Godot 경고(`autowrap minimum size`) 없음

## 10) 작업 체크리스트
- [ ] 폰트 파일 경로 존재 확인
- [ ] 폰트 매핑 표와 실제 씬 일치
- [ ] Close 버튼 위치 스펙 일치
- [ ] 상태 메시지 색상 일치
- [ ] 첫 실행 스모크 테스트 완료
