# GrowingStone UI Design Guide (v1)

## 1) 목적
- 로그인/회원가입 포함 초기 UX를 일관된 톤으로 통일한다.
- Godot `Control + Container + Theme` 기반으로 해상도 변화에도 깨지지 않는 UI를 만든다.
- 아이콘/이미지 에셋은 기존 리소스를 재사용하고, 스타일 토큰부터 먼저 고정한다.

## 2) 스타일 방향
- 키워드: `미니멀`, `부드러운 파스텔`, `돌/자연 느낌`, `여백 중심`
- 레이아웃: 중앙 카드형 + 수직 흐름 + 큰 터치 타겟 버튼
- 대비: 배경은 밝게, CTA 버튼은 중간 채도 그린으로 강조

## 3) 디자인 토큰

### 색상
- `bg/app`: `#DCDCDC` (앱 전체 배경)
- `bg/card`: `#F2F2F2` (카드 배경)
- `text/primary`: `#1F1F1F`
- `text/secondary`: `#555555`
- `brand/primary`: `#ACD8B9` (메인 버튼, 이미지 메인 컬러 기준)
- `brand/primary_hover`: `#9FCFAA`
- `brand/primary_pressed`: `#8FC39A`
- `state/error`: `#D9534F`
- `state/success`: `#2E7D32`
- 버튼 텍스트는 `#1F1F1F` 사용 (`#FFFFFF` 지양, 대비 부족)
- 텍스트 대비 목표: 일반 텍스트 `4.5:1` 이상 (WCAG AA)

### 타이포그래피
- 타이틀: 48~56
- 섹션/설명: 18~24
- 본문/입력/버튼: 24~32
- 상태 메시지: 16~20

### 간격/치수
- 카드 내부 패딩: 32
- 요소 간 기본 간격: 12
- 섹션 간 간격: 24
- 입력/버튼 높이: 44~56
- 최소 터치 타겟: 44 이상

## 4) 컴포넌트 규격

### 입력창 (LineEdit)
- 폭: 카드 폭 기준 100%
- 높이: 44 이상
- Placeholder 사용, 라벨은 필요 시 상단 배치
- 비밀번호는 `secret=true`

### 기본 버튼 (Button)
- 폭: 카드 폭 기준 100%
- 높이: 44~56
- 모서리 라운드 일관 적용
- Hover/Pressed 색상 토큰 적용

### 상태 라벨 (Label)
- 기본 문구는 비워둔다.
- 성공/오류 메시지는 색상으로 구분한다.
- `autowrap` 사용 시 `custom_minimum_size`를 반드시 지정한다.

## 5) 로그인 화면 구조
- 루트: `Control`
- 중앙 정렬: `CenterContainer`
- 카드: `PanelContainer` (내부 `MarginContainer`)
- 본문: `VBoxContainer`
  - Title Label
  - Subtitle Label
  - Email LineEdit
  - Password LineEdit
  - Login Button
  - SignUp Button
  - Status Label
  - Language Row (`HBoxContainer`)

## 6) 상태 정의
- `idle`: 초기 상태, 상태 라벨 비움
- `loading`: 버튼 비활성 + "처리 중..."
- `success`: 성공 메시지 + 다음 화면 전환
- `error`: 서버 메시지 우선 노출

## 7) 아이콘/이미지 사용 규칙
- 현재 보유 에셋 우선 사용
- 새 에셋 추가 시 파일명 규칙:
  - `ui_icon_<name>.png`
  - `ui_illust_<name>.png`
- 컬러가 맞지 않으면 원본 수정 대신 `modulate` 또는 Theme 우선

## 8) 반응형 규칙
- 절대 좌표(`offset`) 중심 배치 금지
- `Container` 기반 배치 우선
- 작은 창에서도 버튼/입력창 가로폭 유지, 세로 스크롤 허용

## 9) 구현 순서 (권장)
1. 로그인/회원가입 화면부터 토큰 적용
2. 공용 Theme 리소스 분리 (`res://ui/theme/*.tres`)
3. 버튼/입력/라벨 공용 스타일 타입 정의
4. 메인/연구소/소셜 화면으로 확장

## 10) 완료 기준 (DoD)
- 첫 실행 시 레이아웃 깨짐 없음
- 로그인/회원가입/오류 메시지 스타일 일관
- 해상도 변경 시 UI 비틀림 없음
- 텍스트 잘림/겹침 없음
- 경고(`autowrap minimum size`) 없음
