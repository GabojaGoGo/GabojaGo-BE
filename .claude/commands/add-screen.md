# 새 화면 추가

1. `lib/screens/` 에 파일 생성
2. 상태 필요 시 `StatefulWidget`, 없으면 `StatelessWidget`
3. 색상 상수는 파일 상단 `const _kPrimary` 등으로 선언
4. `main.dart` routes에 등록 (필요 시)
5. 호출부에서 `Navigator.push` 또는 named route 연결

디자인 컨벤션:
- 카드: `BorderRadius.circular(16)`, `Border.all(color: _kBorder)`
- 기본 배경: `Color(0xFFF8F9FA)`
- 주색: `Color(0xFF2E7D6B)`
- 텍스트: `_kText1(1A1A1A)` / `_kText2(707070)` / `_kText3(9E9E9E)`

화면명/기능: $ARGUMENTS
