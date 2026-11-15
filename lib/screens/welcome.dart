import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import 'auth.dart';
import 'clothes.dart';
import 'profile.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    final AppState s = AppState.instance;
    Widget next;
    if (!s.loggedIn) {
      next = const LoginScreen();
    } else if (!s.hasProfile) {
      next = const ProfileScreen();
    } else {
      next = const ClothesScreen();
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => next));
  }

  Widget _step(String number, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 14, color: kSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '입어봄 (가칭)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kBlue),
              ),
              const SizedBox(height: 28),
              const Text(
                '사기 전에,\n먼저 입어보세요',
                style: TextStyle(fontSize: 34, height: 1.25, fontWeight: FontWeight.w700, color: kInk),
              ),
              const SizedBox(height: 16),
              const Text(
                '내 사진과 옷 사진만 있으면 입은 모습을 바로 확인할 수 있어요.',
                style: TextStyle(fontSize: 16, height: 1.6, color: kSub),
              ),
              const SizedBox(height: 32),
              _step('1', '내 사진 등록', '얼굴·전신 사진과 키, 몸무게', kInk),
              const SizedBox(height: 12),
              _step('2', '옷 사진 올리기', '갤러리에서 고르거나 바로 촬영', kInk),
              const SizedBox(height: 12),
              _step('3', '입은 모습 확인', 'AI가 내 몸에 옷을 입혀 보여줘요', kBlue),
              const Spacer(),
              FilledButton(onPressed: () => _start(context), child: const Text('시작하기')),
              const SizedBox(height: 14),
              const Text(
                '올린 사진은 입어보기 결과를 만드는 데만 사용돼요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
