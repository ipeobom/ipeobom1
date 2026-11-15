import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import 'clothes.dart';
import 'profile.dart';

/// 테스트 버전: 실제 인증 없이 로그인 처리한다. Firebase 연결 후 교체.
Future<void> finishLogin(BuildContext context, String method) async {
  await AppState.instance.logIn(method);
  if (!context.mounted) {
    return;
  }
  final Widget next = AppState.instance.hasProfile ? const ClothesScreen() : const ProfileScreen();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => next),
    (Route<dynamic> route) => route.isFirst,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _social(String label, Color background, Color foreground, String method, {BorderSide? side}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(52),
          side: side,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: () => finishLogin(context, method),
        child: Text(label),
      ),
    );
  }

  void _emailLogin() {
    if (!_email.text.contains('@') || _password.text.isEmpty) {
      showMsg(context, '이메일과 비밀번호를 입력해 주세요.');
      return;
    }
    finishLogin(context, 'email');
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
              const Text('로그인', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 8),
              const Text('쓰던 계정으로 3초 만에 시작하세요.', style: TextStyle(fontSize: 15, color: kSub)),
              const SizedBox(height: 24),
              // 정식 버전에서는 각 회사의 공식 로그인 버튼 이미지로 교체한다.
              _social('네이버로 계속하기', const Color(0xFF03C75A), kInk, 'naver'),
              _social('카카오로 계속하기', const Color(0xFFFEE500), const Color(0xFF191919), 'kakao'),
              _social(
                '구글로 계속하기',
                Colors.white,
                const Color(0xFF1F1F1F),
                'google',
                side: const BorderSide(color: Color(0xFF747775), width: 1.5),
              ),
              const SizedBox(height: 14),
              const Row(
                children: <Widget>[
                  Expanded(child: Divider(color: kLine)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('또는 이메일로', style: TextStyle(fontSize: 13, color: kSub)),
                  ),
                  Expanded(child: Divider(color: kLine)),
                ],
              ),
              const SizedBox(height: 20),
              const FieldLabel('이메일'),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'name@example.com'),
              ),
              const SizedBox(height: 14),
              const FieldLabel('비밀번호'),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(hintText: '비밀번호 입력'),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _emailLogin, child: const Text('로그인')),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text('회원가입'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RecoverScreen()),
                    ),
                    child: const Text('아이디·비밀번호 찾기'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '테스트 버전: 실제 계정 확인 없이 로그인됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _password2 = TextEditingController();
  bool _terms = false;
  bool _privacy = false;
  bool _photo = false;
  bool _marketing = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Widget _agree(String label, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: (bool? v) => onChanged(v ?? false),
      title: Text(label, style: const TextStyle(fontSize: 15, color: kInk)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: kBlue,
    );
  }

  void _submit() {
    if (!_email.text.contains('@')) {
      showMsg(context, '이메일을 확인해 주세요.');
      return;
    }
    if (_password.text.length < 8) {
      showMsg(context, '비밀번호는 8자 이상이어야 해요.');
      return;
    }
    if (_password.text != _password2.text) {
      showMsg(context, '비밀번호가 서로 달라요.');
      return;
    }
    if (!_terms || !_privacy || !_photo) {
      showMsg(context, '필수 항목에 동의해 주세요.');
      return;
    }
    finishLogin(context, 'email');
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
              const Text('회원가입', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 24),
              const FieldLabel('이메일 (아이디)'),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'name@example.com'),
              ),
              const SizedBox(height: 14),
              const FieldLabel('휴대폰 번호'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '010-0000-0000'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: OutlinedButton(
                      onPressed: () => showMsg(context, '테스트 버전에서는 문자 인증을 건너뜁니다.'),
                      child: const Text('인증'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const FieldLabel('비밀번호'),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(hintText: '8자 이상'),
              ),
              const SizedBox(height: 14),
              const FieldLabel('비밀번호 확인'),
              TextField(
                controller: _password2,
                obscureText: true,
                decoration: const InputDecoration(hintText: '한 번 더 입력'),
              ),
              const SizedBox(height: 16),
              _agree('[필수] 서비스 이용약관 동의', _terms, (bool v) => setState(() => _terms = v)),
              _agree('[필수] 개인정보 수집·이용 동의', _privacy, (bool v) => setState(() => _privacy = v)),
              _agree('[필수] 얼굴·신체 사진 처리 동의', _photo, (bool v) => setState(() => _photo = v)),
              _agree('[선택] 혜택·이벤트 알림 받기', _marketing, (bool v) => setState(() => _marketing = v)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('가입하기')),
            ],
          ),
        ),
      ),
    );
  }
}

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  String _tab = 'id';
  String _method = 'phone';

  @override
  Widget build(BuildContext context) {
    final bool isId = _tab == 'id';
    final bool usePhone = isId || _method == 'phone';
    String action;
    if (isId) {
      action = '아이디 찾기';
    } else if (usePhone) {
      action = '비밀번호 재설정하기';
    } else {
      action = '재설정 링크 보내기';
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '아이디·비밀번호 찾기',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kInk),
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'id', label: Text('아이디 찾기')),
                  ButtonSegment<String>(value: 'pw', label: Text('비밀번호 찾기')),
                ],
                selected: <String>{_tab},
                showSelectedIcon: false,
                onSelectionChanged: (Set<String> s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 16),
              Text(
                isId ? '가입할 때 인증한 휴대폰 번호로 아이디와 가입 방식을 알려드려요.' : '본인 확인 방법을 선택해 주세요.',
                style: const TextStyle(fontSize: 15, height: 1.6, color: kSub),
              ),
              if (!isId) ...<Widget>[
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'phone', label: Text('휴대폰 문자')),
                    ButtonSegment<String>(value: 'email', label: Text('이메일')),
                  ],
                  selected: <String>{_method},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<String> s) => setState(() => _method = s.first),
                ),
              ],
              const SizedBox(height: 20),
              if (usePhone) ...<Widget>[
                const FieldLabel('휴대폰 번호'),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(hintText: '010-0000-0000'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 124,
                      child: OutlinedButton(
                        onPressed: () => showMsg(context, '테스트 버전에서는 문자가 발송되지 않아요.'),
                        child: const Text('인증번호 받기'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const FieldLabel('인증번호'),
                const TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: '문자로 받은 6자리 숫자'),
                ),
              ] else ...<Widget>[
                const FieldLabel('이메일'),
                const TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(hintText: 'name@example.com'),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => showMsg(context, '테스트 버전에서는 아직 동작하지 않아요.'),
                child: Text(action),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  '네이버·카카오·구글로 가입하셨다면 비밀번호가 따로 없어요. 로그인 화면에서 같은 계정으로 계속하기를 눌러주세요.',
                  style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF333333)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
