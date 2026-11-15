import 'dart:io';

import 'package:flutter/material.dart';

import '../services/tryon_engine.dart';
import '../theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.garmentPath,
    required this.categoryLabel,
  });

  final TryOnResult result;
  final String garmentPath;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('입어본 모습', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 440,
                  color: const Color(0xFFE5E7EB),
                  child: Image.file(File(result.imagePath), fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              if (result.isMock) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    '테스트 버전: 아직 AI 엔진이 연결되지 않아 올린 사진이 그대로 보여요.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF333333)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                ),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(garmentPath), width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('키·몸무게 기준 추천 사이즈', style: TextStyle(fontSize: 13, color: kSub)),
                          SizedBox(height: 2),
                          Text('준비 중', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
                        ],
                      ),
                    ),
                    Text(categoryLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kSub)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showMsg(context, '저장 기능은 준비 중이에요.'),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('저장'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showMsg(context, '공유 기능은 준비 중이에요.'),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('공유'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('다른 옷 입어보기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
