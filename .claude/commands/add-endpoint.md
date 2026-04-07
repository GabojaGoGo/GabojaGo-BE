# 백엔드 엔드포인트 추가

순서:
1. **Controller** — `@GetMapping/@PostMapping` + `@RequestParam` 추가
2. **Service** — 비즈니스 로직 메서드 추가
3. **Repository** — 필요 시 JPA 쿼리 추가
4. **DTO** — 응답 record/class 추가 (Controller 내 record 활용)
5. **api_service.dart** — Flutter 호출 메서드 추가

컨벤션:
- Controller record로 Request body 정의 (별도 파일 불필요)
- 인증 필요 시 `@AuthenticationPrincipal String userId`
- 에러는 `ResponseEntity` 상태코드로 처리

추가할 기능: $ARGUMENTS
