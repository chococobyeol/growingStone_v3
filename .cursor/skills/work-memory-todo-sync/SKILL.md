---
name: work-memory-todo-sync
description: Updates docs/TODO.md after each code task completion, marks done items, and waits for user approval before next task. Use when completing any code modification or creation to sync work state and enforce approval checkpoints.
---

# 작업 기억 동기화 및 TODO 업데이트

**원칙:** 하나의 코드 작업(수정/생성)이 끝날 때마다 아래 절차를 100% 실행한다.

## 필수 절차 (매 작업 완료 시)

1. **상태 업데이트:** `docs/TODO.md` 파일을 열람한다.
2. **완료 처리:** 방금 완료한 작업 항목의 `[ ]`를 `[x]`로 변경한다.
3. **다음 할 일 명시:** 채팅에 아래 양식으로 출력한다.

```
✅ 방금 완료한 작업: [구체적 내용]
🎯 다음에 진행할 작업: [TODO.md 기준 다음 미완료 항목]
```

4. **대기:** 사용자가 "다음 작업 진행해" 또는 유사한 승인을 할 때까지 **다음 코딩을 시작하지 않는다.**

## 예시

**작업 완료 후 출력 예:**
```
✅ 방금 완료한 작업: LabUI.tscn 버튼 이벤트 연결
🎯 다음에 진행할 작업: ElementCell 스타일 수정
```

## 예외

- `docs/TODO.md`가 없으면 새로 생성한다. 구조는 `- [ ] 작업명` 형식의 체크리스트로 한다.
- 사용자가 별도로 "계속해" 등으로 다음 작업 지시를 하면 승인으로 간주한다.
