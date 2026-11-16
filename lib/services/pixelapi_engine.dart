import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'tryon_engine.dart';

/// 빌드할 때 GitHub 비밀값에서 넣어주는 PixelAPI 키. 비어 있으면 쓰지 않는다.
/// 주의: 테스트 빌드 전용 방식이다. 출시 전에는 키를 서버로 옮겨야 한다.
const String kPixelApiKey = String.fromEnvironment('PIXELAPI_KEY');

const String _base = 'https://api.pixelapi.dev/v1/virtual-tryon';

/// PixelAPI 가상 피팅 엔진.
class PixelApiEngine implements TryOnEngine {
  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Bearer $kPixelApiKey',
        'content-type': 'application/json',
      };

  @override
  Future<TryOnResult> generate(TryOnRequest request) async {
    final String person = base64Encode(await File(request.personImagePath).readAsBytes());
    final String garment = base64Encode(await File(request.garmentImagePath).readAsBytes());

    final http.Response submit = await http.post(
      Uri.parse(_base),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'person_image': person,
        'garment_image': garment,
        'category': _category(request.category),
      }),
    );
    final Map<String, dynamic> job = _decode(submit, 'submit');
    final String jobId = (job['job_id'] ?? '').toString();
    if (jobId.isEmpty) {
      throw TryOnException(
        '입어보기를 시작하지 못했어요.',
        detail: 'engine=pixelapi step=submit body=${_clip(submit.body)}',
      );
    }

    for (int i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      final http.Response poll = await http.get(
        Uri.parse('$_base/jobs/${Uri.encodeComponent(jobId)}'),
        headers: _headers,
      );
      final Map<String, dynamic> data = _decode(poll, 'poll');
      final String status = (data['status'] ?? '').toString();
      if (status == 'completed') {
        final dynamic b64 = data['result_image_b64'];
        if (b64 != null && b64.toString().isNotEmpty) {
          String raw = b64.toString();
          final int comma = raw.indexOf(',');
          if (raw.startsWith('data:') && comma > 0) {
            raw = raw.substring(comma + 1);
          }
          return _save(base64Decode(raw));
        }
        final dynamic url = data['output_url'];
        if (url != null) {
          final http.Response img = await http.get(Uri.parse(url.toString()));
          if (img.statusCode == 200) {
            return _save(img.bodyBytes);
          }
        }
        throw TryOnException(
          '결과 이미지를 받지 못했어요.',
          detail: 'engine=pixelapi step=result body=${_clip(poll.body)}',
        );
      }
      if (status == 'failed') {
        final String reason = (data['error_message'] ?? data['error'] ?? '').toString();
        throw TryOnException(
          '입어보기에 실패했어요. ${reason.isEmpty ? '' : '($reason)'}',
          code: 'failed',
          detail: 'engine=pixelapi step=poll body=${_clip(poll.body)}',
        );
      }
    }
    throw TryOnException('시간이 너무 오래 걸려요. 잠시 후 다시 시도해 주세요.');
  }

  Future<TryOnResult> _save(List<int> bytes) async {
    final File out = File(
      '${Directory.systemTemp.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await out.writeAsBytes(bytes);
    return TryOnResult(imagePath: out.path, isMock: false);
  }

  String _category(String category) {
    switch (category) {
      case 'bottom':
        return 'lowerbody';
      case 'dress':
        return 'dress';
      default:
        return 'upperbody';
    }
  }

  String _clip(String text) => text.length > 400 ? text.substring(0, 400) : text;

  Map<String, dynamic> _decode(http.Response res, String step) {
    Map<String, dynamic> json = <String, dynamic>{};
    try {
      final dynamic parsed = jsonDecode(utf8.decode(res.bodyBytes));
      if (parsed is Map<String, dynamic>) {
        json = parsed;
      }
    } catch (_) {
      // JSON이 아니면 아래에서 상태 코드로 처리한다.
    }
    if (res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 202) {
      return json;
    }
    String message;
    if (res.statusCode == 401 || res.statusCode == 403) {
      message = '엔진 키가 올바르지 않아요. (설정 확인 필요)';
    } else if (res.statusCode == 402) {
      message = '무료 크레딧을 다 썼어요.';
    } else if (res.statusCode == 429) {
      message = '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';
    } else if (res.statusCode == 413) {
      message = '사진이 너무 커요. 더 작은 사진을 써주세요.';
    } else {
      message = '입어보기에 실패했어요. (${res.statusCode})';
    }
    throw TryOnException(
      message,
      code: '${res.statusCode}',
      detail: 'engine=pixelapi step=$step http=${res.statusCode} body=${_clip(res.body)}',
    );
  }
}
