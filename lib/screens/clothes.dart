import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/tryon_engine.dart';
import '../theme.dart';
import '../widgets/pick.dart';
import 'profile.dart';
import 'result.dart';
import 'welcome.dart';

class ClothesScreen extends StatefulWidget {
  const ClothesScreen({super.key});

  @override
  State<ClothesScreen> createState() => _ClothesScreenState();
}

class _ClothesScreenState extends State<ClothesScreen> {
  static const Map<String, String> _categories = <String, String>{
    'top': '상의',
    'bottom': '하의',
    'dress': '원피스',
    'outer': '아우터',
  };

  String? _garment;
  String _category = 'top';
  bool _loading = false;

  Future<void> _pick() async {
    final String? path = await pickPhoto(context);
    if (path == null || !mounted) {
      return;
    }
    setState(() => _garment = path);
  }

  Future<void> _tryOn() async {
    final AppState s = AppState.instance;
    final String? garment = _garment;
    final String? person = s.bodyPath ?? s.facePath;
    if (garment == null) {
      showMsg(context, '옷 사진을 먼저 올려주세요.');
      return;
    }
    if (person == null) {
      showMsg(context, '내 사진을 먼저 등록해 주세요.');
      return;
    }
    if (s.remainingToday <= 0) {
      showMsg(context, '오늘의 무료 횟수를 모두 사용했어요. 내일 다시 이용해 주세요.');
      return;
    }
    setState(() => _loading = true);
    try {
      final TryOnResult result = await tryOnEngine.generate(
        TryOnRequest(
          personImagePath: person,
          garmentImagePath: garment,
          category: _category,
          heightCm: s.heightCm,
          weightKg: s.weightKg,
        ),
      );
      await s.consumeTry();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            result: result,
            garmentPath: garment,
            categoryLabel: _categories[_category] ?? '',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        showMsg(context, '입어보기에 실패했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AppState.instance.logOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int remaining = AppState.instance.remainingToday;
    final String? garment = _garment;
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            tooltip: '내 정보 수정',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen(editing: true)),
            ),
          ),
          IconButton(tooltip: '로그아웃', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '입어볼 옷 사진을\n올려주세요',
                style: TextStyle(fontSize: 26, height: 1.3, fontWeight: FontWeight.w700, color: kInk),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pick,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 280,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF9CA3AF), width: 1.5),
                  ),
                  child: garment != null
                      ? Image.file(File(garment), fit: BoxFit.contain, width: double.infinity)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.checkroom, size: 44, color: kInk),
                            SizedBox(height: 16),
                            Text('눌러서 옷 사진 올리기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
                            SizedBox(height: 6),
                            Text('옷만 나온 정면 사진이 가장 잘 나와요', style: TextStyle(fontSize: 14, color: kSub)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              const FieldLabel('옷 종류'),
              Wrap(
                spacing: 8,
                children: _categories.entries.map((MapEntry<String, String> e) {
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: _category == e.key,
                    onSelected: (_) => setState(() => _category = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                '오늘 남은 무료 횟수: $remaining / ${AppState.dailyFreeLimit}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSub),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _tryOn,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('입어보기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
