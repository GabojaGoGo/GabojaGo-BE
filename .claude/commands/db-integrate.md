# DB 연동 작업

다음 순서로 진행:

1. **백엔드 엔드포인트 확인** — `UserDataController.java` 또는 해당 Controller 읽기
2. **UserDataService.dart 확인** — 이미 구현된 메서드 있는지 확인
3. **화면에서 더미 데이터 제거** — const 상수 → UserDataService 호출로 교체
4. **빈 상태 UI 추가** — 데이터 없을 때 안내 문구
5. **쓰기 동작 구현** — 추가/삭제/수정 후 `setState()` 호출

대상 화면: $ARGUMENTS
