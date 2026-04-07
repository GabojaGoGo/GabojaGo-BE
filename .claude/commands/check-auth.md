# 인증/취향 관련 이슈 디버깅

증상별 체크리스트:

**로그인 후 데이터 사라짐**
- `syncFromServer()` await 여부 확인 (main.dart `_handleDeepLink`)
- `AuthService.updatePrefs()` 호출 여부 확인 (취향 저장 시)

**취향 설정이 반영 안 됨**
- `travel_setup_screen.dart` → `AuthService.updatePrefs()` + `UserDataService.savePrefs()` 둘 다 호출하는지 확인
- `MainShell._buildInitialPrefs()` → ud_prefs 우선 읽는지 확인

**API 연결 안 됨**
- `.env` `API_BASE_URL` 확인 → `http://jyys-MacBook-Pro.local:8080/api`
- 백엔드 실행 중인지 확인: `docker compose ps`
- 같은 WiFi 연결 여부 확인

**JWT 만료**
- `getValidAccessToken()` → 자동 refresh 시도
- refresh 실패 시 `_clearLocal()` → 로그인 화면으로

증상: $ARGUMENTS
