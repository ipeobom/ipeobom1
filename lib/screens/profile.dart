import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/pick.dart';
import 'clothes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.editing = false});

  /// 옷 올리기 화면에서 수정하러 들어온 경우 true.
  final bool editing;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  String? _face;
  String? _body;

  @override
  void initState() {
    super.initState();
    final AppState s = AppState.instance;
    _face = s.facePath;
    _body = s.bodyPath;
    if (s.heightCm != null) {
      _height.text = '${s.heightCm}';
    }
    if (s.weightKg != null) {
      _weight.text = '${s.weightKg}';
    }
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pick(bool face) async {
    final String? path = await pickPhoto(context);
    if (path == null || !mounted) {
      return;
    }
    setState(() {
      if (face) {
        _face = path;
      } else {
        _body = path;
      }
    });
  }

  Widget _tile(String title, String note, Color noteColor, IconData icon, String? path, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 190,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9CA3AF), width: 1.5),
          ),
          child: path != null
              ? Image.file(File(path), fit: BoxFit.cover, width: double.infinity)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon, size: 36, color: kInk),
                    const SizedBox(height: 10),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk)),
                    const SizedBox(height: 6),
                    Text(note, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: noteColor)),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    final int? h = int.tryParse(_height.text.trim());
    final int? w = int.tryParse(_weight.text.trim());
    final String? face = _face;
    final String? body = _body;
    if (face == null) {
      showMsg(context, '얼굴 사진을 등록해 주세요.');
      return;
    }
    if (body == null) {
      showMsg(context, '전신 사진을 등록해 주세요. 옷은 전신 사진에 입혀져요.');
      return;
    }
    if (h == null || h < 100 || h > 230 || w == null || w < 25 || w > 250) {
      showMsg(context, '키와 몸무게를 확인해 주세요.');
      return;
    }
    await AppState.instance.saveProfile(face: face, body: body, height: h, weight: w);
    if (!mounted) {
      return;
    }
    if (widget.editing) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ClothesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('내 정보를 알려주세요', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 8),
              const Text('한 번만 등록하면 계속 사용할 수 있어요.', style: TextStyle(fontSize: 15, color: kSub)),
              const SizedBox(height: 28),
              Row(
                children: <Widget>[
                  _tile('얼굴 사진', '필수', kBlue, Icons.face_outlined, _face, () => _pick(true)),
                  const SizedBox(width: 12),
                  _tile('전신 사진', '필수 · 입어보기에 사용', kBlue, Icons.accessibility_new, _body, () => _pick(false)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  '전신 사진 잘 찍는 법\n'
                  '· 폰을 세로로 들고 찍어 주세요\n'
                  '· 머리부터 발끝까지, 몸이 화면을 꽉 채우게\n'
                  '· 정면을 보고 팔은 몸 옆에 자연스럽게\n'
                  '· 몸에 붙는 옷을 입으면 더 정확해요\n'
                  '· 테두리나 글자가 들어간 사진은 피해 주세요',
                  style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF333333)),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const FieldLabel('키'),
                        TextField(
                          controller: _height,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '170', suffixText: 'cm'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const FieldLabel('몸무게'),
                        TextField(
                          controller: _weight,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '60', suffixText: 'kg'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '키와 몸무게는 체형 반영과 사이즈 추천에 사용돼요.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 32),
              FilledButton(onPressed: _next, child: const Text('다음')),
            ],
          ),
        ),
      ),
    );
  }
}
