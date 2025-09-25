// 1. 먼저 SharedPreferences를 사용하기 위해 pubspec.yaml에 추가
// dependencies:
//   shared_preferences: ^2.2.2

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/onboarding_content.dart';
import 'widgets/page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: '포트홀을 발견하셨나요?',
      description: '도로 위의 위험한 포트홀을\n쉽게 신고할 수 있어요',
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    ),
    OnboardingData(
      title: '사진으로 간편하게',
      description: '카메라나 갤러리에서\n사진을 선택하여 신고하세요',
      icon: Icons.camera_alt_rounded,
      color: Colors.blue,
    ),
    OnboardingData(
      title: '실시간 위치 확인',
      description: '현재 위치를 기반으로\n정확한 신고가 가능해요',
      icon: Icons.location_on_rounded,
      color: Colors.green,
    ),
    OnboardingData(
      title: '안전한 도로 만들기',
      description: '여러분의 신고로\n모두가 안전한 길을 만들어가요',
      icon: Icons.favorite_rounded,
      color: Colors.red,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 온보딩 완료 처리 및 홈으로 이동
  void _startApp() async {
    await _setOnboardingCompleted();
    if (mounted) {
      context.go('/home');
    }
  }

  // 온보딩 완료 상태를 저장
  Future<void> _setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  TextButton(
                    onPressed: _startApp,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'KakaoSmallSans',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingContent(data: _pages[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: PageIndicator(
                currentPage: _currentPage,
                totalPages: _pages.length,
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '이전',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'KakaoSmallSans',
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),

                  const SizedBox(width: 16),

                  // Next/Start button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? _startApp
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'KakaoSmallSans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 온보딩 상태 확인 유틸리티 클래스
class OnboardingHelper {
  static const String _onboardingKey = 'onboarding_completed';

  // 온보딩 완료 여부 확인
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // 온보딩 완료 상태 설정
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // 온보딩 상태 초기화 (개발/테스트용)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}

// main.dart 또는 라우터 설정에서 사용할 초기 경로 결정 함수
class AppInitializer {
  static Future<String> getInitialRoute() async {
    final isCompleted = await OnboardingHelper.isOnboardingCompleted();
    return isCompleted ? '/home' : '/onboarding';
  }
}

// GoRouter 설정 예시 (main.dart에서 사용)
/*
final GoRouter router = GoRouter(
  initialLocation: await AppInitializer.getInitialRoute(),
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    // 다른 라우트들...
  ],
);
*/

// 또는 Splash Screen에서 처리하는 방법
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // 스플래시 화면 표시 시간

    final isCompleted = await OnboardingHelper.isOnboardingCompleted();

    if (mounted) {
      if (isCompleted) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              '포트홀 신고',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'KakaoSmallSans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
