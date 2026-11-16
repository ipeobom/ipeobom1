import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'tryon_engine.dart';

/// 빌드할 때 GitHub 비밀값에서 넣어주는 Gemini API 키. 비어 있으면 쓰지 않는다.
/// 주의: 테스트 빌드 전용 방식이다. 출시 전에는 키를 서버로 옮겨야 한다.
const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

const String _model = 'gemini-2.5-flash-image';

/// 구글 Gemini 이미지 모델로 옷을 입혀 보는 엔진.
class GeminiEngine implements TryOnEngine {
  @override
  Future<TryOnResult> generate(TryOnRequest request) async {
    final List<int> person = await File(request.personImagePath).readAsBytes();
    final List<int> garment = await File(request.garmentImagePath).readAsBytes();

    final String prompt = '첫 번째 사진의 사람에게 두 번째 사진의 ${_label(request.category)}을(를) 입혀 주세요. '
        '얼굴, 머리 모양, 피부색, 체형, 자세, 배경은 첫 번째 사진 그대로 유지하고, '
        '옷의 색상, 무늬, 소재, 디테일은 두 번째 사진과 똑같이 해주세요. '
        '사실적인 사진 한 장으로 만들어 주세요.'
        '${_bodyHint(request)}';

    final http.Response res = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent'),
      headers: <String, String>{
        'x-goog-api-key': kGeminiApiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'text': prompt},
              _image(request.personImagePath, person),
              _image(request.garmentImagePath, garment),
            ],
          },
        ],
        'generationConfig': <String, dynamic>{
          'responseModalities': <String>['TEXT', 'IMAGE'],
        },
      }),
    );

    final String body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw TryOnException(
        _message(res.statusCode, body),
        code: '${res.statusCode}',
        detail: 'engine=gemini http=${res.statusCode} body=${_clip(body)}',
      );
    }

    final dynamic json = jsonDecode(body);
    final List<dynamic> candidates = (json['candidates'] as List<dynamic>?) ?? <dynamic>[];
    for (final dynamic candidate in candidates) {
      final List<dynamic> parts = (candidate['content']?['parts'] as List<dynamic>?) ?? <dynamic>[];
      for (final dynamic part in parts) {
        final dynamic inline = part['inlineData'] ?? part['inline_data'];
        if (inline != null && inline['data'] != null) {
          final File out = File(
            '${Directory.systemTemp.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await out.writeAsBytes(base64Decode(inline['data'].toString()));
          return TryOnResult(imagePath: out.path, isMock: false);
        }
      }
    }
    throw TryOnException(
      '이미지를 만들지 못했어요. 다른 사진으로 다시 시도해 주세요.',
      code: 'no_image',
      detail: 'engine=gemini http=200 body=${_clip(body)}',
    );
  }

  Map<String, dynamic> _image(String path, List<int> bytes) {
    final String lower = path.toLowerCase();
    final String mime = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    return <String, dynamic>{
      'inline_data': <String, dynamic>{'mime_type': mime, 'data': base64Encode(bytes)},
    };
  }

  String _label(String category) {
    switch (category) {
      case 'bottom':
        return '하의';
      case 'dress':
        return '원피스';
      case 'outer':
        return '아우터';
      default:
        return '상의';
    }
  }

  String _bodyHint(TryOnRequest r) {
    if (r.heightCm == null || r.weightKg == null) {
      return '';
    }
    return ' 이 사람은 키 ${r.heightCm}cm, 몸무게 ${r.weightKg}kg이니 옷의 핏을 그에 맞게 자연스럽게 표현해 주세요.';
  }

  String _clip(String text) => text.length > 400 ? text.substring(0, 400) : text;

  String _message(int status, String body) {
    if (status == 429) {
      return '무료 사용 한도에 걸렸어요. (Gemini 무료 등급에 이미지 생성이 없거나 오늘 한도를 다 썼어요)';
    }
    if (status == 400 && body.contains('API_KEY_INVALID')) {
      return '엔진 키가 올바르지 않아요. (설정 확인 필요)';
    }
    if (status == 403) {
      return '이 키로는 이미지 생성을 쓸 수 없어요. (권한 또는 지역 제한)';
    }
    return '입어보기에 실패했어요. ($status)';
  }
}
