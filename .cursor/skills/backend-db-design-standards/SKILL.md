---
name: backend-db-design-standards
description: Standards for backend and database design: transaction safety for currency/data changes, server-side input validation, and error encapsulation. Use when designing or implementing backend APIs, database operations, RPCs, Supabase edge functions, or data mutation logic.
---

# 백엔드 및 데이터베이스 설계 표준

백엔드/DB 설계·구현 시 다음 3가지 원칙을 반드시 적용한다.

---

## 1. 트랜잭션 안전성

재화 변동, 데이터 삽입·삭제·수정은 **반드시 원자적 트랜잭션** 안에서 처리한다.

**적용 대상 예:**
- 재화(gold, crystal 등) 증감
- 인벤토리 추가/제거
- 여러 테이블에 걸친 데이터 변경

**지침:**
- Postgres RPC: `BEGIN`/`COMMIT`/`ROLLBACK` 또는 `pg_procedure`에서 묶어 처리
- Supabase Edge Function: DB 호출을 단일 트랜잭션 블록으로 수행
- 중간 실패 시 전체 롤백되어야 함

---

## 2. 입력값 검증

클라이언트 요청 데이터는 **절대 신뢰하지 않고**, 서버에서 항상 검증한다.

**적용 대상:**
- API body, query params, headers
- RPC 인자
- Edge Function 입력

**검증 항목 예:**
- 타입·형식 (숫자, enum, 문자열 길이)
- 범위·제한 (최소/최대값, 열거값)
- 권한·소유권 (해당 유저가 그 리소스에 접근 가능한지)
- SQL injection, XSS 등 보안 위험 데이터

**원칙:** 클라이언트 검증은 UX용이며, 서버 검증이 실제 보안·무결성의 기준이다.

---

## 3. 에러 캡슐화

시스템 에러(stack trace, 내부 메시지)를 **클라이언트에 노출하지 않고**, 정제된 Custom Error로 응답한다.

**처리 방법:**
- 로그에는 상세 에러·스택 보관
- 클라이언트 응답에는: `{ code, message }` 형태의 안전한 메시지만 전달
- 예: `{ "code": "INVALID_INPUT", "message": "입력값이 올바르지 않습니다." }`

**금지 사항:**
- DB 에러 메시지 그대로 반환
- 내부 파일 경로·함수명·SQL 노출

---

## 체크리스트

백엔드/DB 작업 시 확인:

```
- [ ] 재화·데이터 변경이 트랜잭션으로 묶여 있는가?
- [ ] 모든 입력값을 서버에서 검증하는가?
- [ ] 클라이언트 응답에 상세 에러가 노출되지 않는가?
```
