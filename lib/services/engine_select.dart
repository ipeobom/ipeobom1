import 'gemini_engine.dart';
import 'perfect_corp_engine.dart';
import 'tryon_engine.dart';

/// 엔진을 바꿀 때는 이 파일만 고친다.
/// Gemini 키가 있으면 Gemini, 없으면 Perfect Corp 키, 둘 다 없으면 가짜 엔진.
final TryOnEngine tryOnEngine = kGeminiApiKey.isNotEmpty
    ? GeminiEngine()
    : (kTryOnApiKey.isNotEmpty ? PerfectCorpEngine() : MockTryOnEngine());
