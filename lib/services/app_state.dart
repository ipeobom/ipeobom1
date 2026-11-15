import 'package:shared_preferences/shared_preferences.dart';

/// 기기 안에 저장하는 임시 상태. 서버(Firebase) 연결 후 이 클래스 내부만 바꾸면 된다.
class AppState {
  AppState._();
  static final AppState instance = AppState._();

  /// 무료 사용자의 하루 입어보기 횟수.
  static const int dailyFreeLimit = 3;

  late SharedPreferences _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
  }

  bool get loggedIn => _p.getBool('loggedIn') ?? false;
  String get loginMethod => _p.getString('loginMethod') ?? '';

  Future<void> logIn(String method) async {
    await _p.setBool('loggedIn', true);
    await _p.setString('loginMethod', method);
  }

  Future<void> logOut() async {
    await _p.setBool('loggedIn', false);
  }

  String? get facePath => _p.getString('facePath');
  String? get bodyPath => _p.getString('bodyPath');
  int? get heightCm => _p.getInt('heightCm');
  int? get weightKg => _p.getInt('weightKg');

  bool get hasProfile => facePath != null && heightCm != null && weightKg != null;

  Future<void> saveProfile({
    required String face,
    String? body,
    required int height,
    required int weight,
  }) async {
    await _p.setString('facePath', face);
    if (body != null) {
      await _p.setString('bodyPath', body);
    }
    await _p.setInt('heightCm', height);
    await _p.setInt('weightKg', weight);
  }

  String _today() {
    final DateTime n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  int get remainingToday {
    if (_p.getString('tryDate') != _today()) {
      return dailyFreeLimit;
    }
    final int left = dailyFreeLimit - (_p.getInt('tryCount') ?? 0);
    return left < 0 ? 0 : left;
  }

  Future<void> consumeTry() async {
    final String today = _today();
    if (_p.getString('tryDate') != today) {
      await _p.setString('tryDate', today);
      await _p.setInt('tryCount', 1);
    } else {
      await _p.setInt('tryCount', (_p.getInt('tryCount') ?? 0) + 1);
    }
  }
}
