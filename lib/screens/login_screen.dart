// login_screen.dart
// 로그인 화면 — 카카오 로그인 + 비회원 둘러보기

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _isLoading = false;
  String? _errorMessage;

  static const _primary = Color(0xFF2E7D6B);
  static const _bg = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── 카카오 로그인 ─────────────────��───────────────────────

  Future<void> _kakaoLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.startKakaoLogin();
      // 브라우저가 열린 후 딥링크 수신을 기다림 (main.dart에서 처리)
      // 로딩 표시는 딥링크 수신 전까지 유지
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '카카오 로그인을 시작할 수 없습니다.\n잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 56),

                  // ── 로고 + 헤드라인 ─────────────────────
                  _Logo(),
                  const SizedBox(height: 48),

                  // ── 카카오 로그인 버튼 ───────────────────
                  _KakaoLoginButton(
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _kakaoLogin,
                  ),

                  // ── 에러 메시지 ────────────────���─────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD32F2F),
                        height: 1.5,
                      ),
                    ),
                  ],

                  // ── 브라우저 대기 안내 ────────────────────
                  if (_isLoading) ...[
                    const SizedBox(height: 20),
                    Text(
                      '카카오 로그인 화면으로 이동 중입니다.\n로그인 완료 후 자동으로 돌아옵니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── 비회원 둘러보기 ───────────────────────
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await AuthService.instance.setGuestMode();
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/main');
                            }
                          },
                    child: Text(
                      '로그인 없이 둘러보기',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: _isLoading
          ? Container(
              height: 3,
              child: const LinearProgressIndicator(
                backgroundColor: Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation(_primary),
              ),
            )
          : null,
    );
  }
}

// ── 로고 위젯 ──────────────────────────────────────────────
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D6B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('🚝', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '가보자Go',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '나만의 여행 혜택 도우미',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '로그인하면 취향 기반 코스 추천과\n모든 여행 혜택을 한눈에 볼 수 있어요.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ── 카카오 로그인 버튼 ─────────────────────────────────────
class _KakaoLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _KakaoLoginButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE500),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF191919),
                    strokeWidth: 2.5,
                  ),
                )
              else ...[
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                const Text(
                  '카카오로 계속하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191919),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
