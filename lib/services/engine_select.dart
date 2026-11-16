import 'perfect_corp_engine.dart';
import 'tryon_engine.dart';

/// 엔진을 바꿀 때는 이 파일만 고친다. 키가 없으면 가짜 엔진으로 동작한다.
final TryOnEngine tryOnEngine = kTryOnApiKey.isEmpty ? MockTryOnEngine() : PerfectCorpEngine();
