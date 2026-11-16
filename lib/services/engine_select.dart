import 'gemini_engine.dart';
import 'perfect_corp_engine.dart';
import 'pixelapi_engine.dart';
import 'tryon_engine.dart';

/// 엔진을 바꿀 때는 이 파일만 고친다. 키가 있는 엔진을 아래 순서로 고른다.
/// PixelAPI → Gemini → Perfect Corp → 가짜 엔진
final TryOnEngine tryOnEngine = kPixelApiKey.isNotEmpty
    ? PixelApiEngine()
    : kGeminiApiKey.isNotEmpty
        ? GeminiEngine()
        : (kTryOnApiKey.isNotEmpty ? PerfectCorpEngine() : MockTryOnEngine());
