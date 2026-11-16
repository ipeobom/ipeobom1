/// 가상 피팅 엔진 연결부.
/// 엔진(구글 Vertex AI, FASHN 등)을 바꿀 때는 TryOnEngine 구현체만 교체한다.
class TryOnRequest {
  TryOnRequest({
    required this.personImagePath,
    required this.garmentImagePath,
    required this.category,
    this.heightCm,
    this.weightKg,
  });

  final String personImagePath;
  final String garmentImagePath;
  final String category;
  final int? heightCm;
  final int? weightKg;
}

class TryOnResult {
  TryOnResult({required this.imagePath, required this.isMock});

  final String imagePath;
  final bool isMock;
}

/// 사용자에게 보여줄 문구를 담은 엔진 오류.
class TryOnException implements Exception {
  TryOnException(this.message, {this.code = ''});

  final String message;
  final String code;
}

abstract class TryOnEngine {
  Future<TryOnResult> generate(TryOnRequest request);
}

/// 테스트용 가짜 엔진: 합성 없이 올린 사진을 그대로 돌려준다.
class MockTryOnEngine implements TryOnEngine {
  @override
  Future<TryOnResult> generate(TryOnRequest request) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return TryOnResult(imagePath: request.personImagePath, isMock: true);
  }
}

