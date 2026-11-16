import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'tryon_engine.dart';

/// 빌드할 때 GitHub 비밀값에서 넣어주는 엔진 키. 비어 있으면 가짜 엔진을 쓴다.
/// 주의: 테스트 빌드 전용 방식이다. 출시 전에는 키를 서버로 옮겨야 한다.
const String kTryOnApiKey = String.fromEnvironment('TRYON_API_KEY');

const String _base = 'https://yce-api-01.makeupar.com/s2s/v2.0';

/// Perfect Corp(YouCam) AI Clothes 가상 피팅 엔진.
class PerfectCorpEngine implements TryOnEngine {
  Map<String, String> get _headers => <String, String>{
        'Authorization': 'Bearer $kTryOnApiKey',
        'content-type': 'application/json',
      };

  @override
  Future<TryOnResult> generate(TryOnRequest request) async {
    final String srcId = await _upload(request.personImagePath);
    final String refId = await _upload(request.garmentImagePath);

    String taskId;
    try {
      taskId = await _createTask(srcId, refId, _category(request.category));
    } on TryOnException catch (e) {
      // 옷 종류 값을 엔진이 받지 않으면 전신 기준으로 한 번 더 시도한다.
      if (e.code != 'invalid_parameter') {
        rethrow;
      }
      taskId = await _createTask(srcId, refId, 'full_body');
    }

    final String resultUrl = await _waitForResult(taskId);
    final http.Response image = await http.get(Uri.parse(resultUrl));
    if (image.statusCode != 200) {
      throw TryOnException('결과 이미지를 받지 못했어요. 다시 시도해 주세요.');
    }
    final File out = File(
      '${Directory.systemTemp.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(image.bodyBytes);
    return TryOnResult(imagePath: out.path, isMock: false);
  }

  String _category(String category) {
    switch (category) {
      case 'bottom':
        return 'lower_body';
      case 'dress':
        return 'full_body';
      default:
        return 'upper_body';
    }
  }

  Future<String> _upload(String path) async {
    final List<int> bytes = await File(path).readAsBytes();
    final bool png = path.toLowerCase().endsWith('.png');
    final http.Response res = await http.post(
      Uri.parse('$_base/file'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'files': <Map<String, dynamic>>[
          <String, dynamic>{
            'content_type': png ? 'image/png' : 'image/jpg',
            'file_name': png ? 'photo.png' : 'photo.jpg',
            'file_size': bytes.length,
          },
        ],
      }),
    );
    final Map<String, dynamic> json = _decode(res, 'file');
    final dynamic file = (json['data']['files'] as List<dynamic>).first;
    final dynamic req = (file['requests'] as List<dynamic>).first;

    final Map<String, String> putHeaders = <String, String>{};
    final dynamic rawHeaders = req['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((dynamic k, dynamic v) {
        if (k.toString().toLowerCase() != 'content-length') {
          putHeaders[k.toString()] = v.toString();
        }
      });
    }
    final http.Response put = await http.put(
      Uri.parse(req['url'].toString()),
      headers: putHeaders,
      body: bytes,
    );
    if (put.statusCode >= 300) {
      throw TryOnException(
        '사진 업로드에 실패했어요. (${put.statusCode})',
        detail: 'step=put http=${put.statusCode} body=${_clip(put.body)}',
      );
    }
    return file['file_id'].toString();
  }

  Future<String> _createTask(String srcId, String refId, String category) async {
    final http.Response res = await http.post(
      Uri.parse('$_base/task/cloth-v4'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'src_file_id': srcId,
        'ref_file_id': refId,
        'garment_category': category,
      }),
    );
    final Map<String, dynamic> json = _decode(res, 'task:$category');
    return json['data']['task_id'].toString();
  }

  Future<String> _waitForResult(String taskId) async {
    for (int i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final http.Response res = await http.get(
        Uri.parse('$_base/task/cloth-v4/${Uri.encodeComponent(taskId)}'),
        headers: _headers,
      );
      final Map<String, dynamic> json = _decode(res, 'poll');
      final dynamic data = json['data'];
      final String status = (data['task_status'] ?? '').toString();
      if (status == 'success') {
        return data['results']['url'].toString();
      }
      if (status == 'error' || data['error'] != null) {
        final String code = _errorCode(data['error']);
        throw TryOnException(
          _message(code),
          code: code,
          detail: 'step=poll body=${_clip(jsonEncode(data))}',
        );
      }
    }
    throw TryOnException('시간이 너무 오래 걸려요. 잠시 후 다시 시도해 주세요.');
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
      // 본문이 JSON이 아니면 아래에서 상태 코드로 처리한다.
    }
    if (res.statusCode == 401) {
      throw TryOnException(
        '엔진 키가 올바르지 않아요. (설정 확인 필요)',
        code: 'unauthorized',
        detail: 'step=$step http=401 body=${_clip(res.body)}',
      );
    }
    if (res.statusCode != 200 || json['data'] == null) {
      final String code = _errorCode(json['error_code'] ?? json['error']);
      throw TryOnException(
        _message(code.isEmpty ? '${res.statusCode}' : code),
        code: code,
        detail: 'step=$step http=${res.statusCode} body=${_clip(res.body)}',
      );
    }
    return json;
  }

  String _errorCode(dynamic error) {
    if (error == null) {
      return '';
    }
    if (error is Map) {
      return (error['code'] ?? error['error_code'] ?? error['message'] ?? '').toString();
    }
    return error.toString();
  }

  String _message(String code) {
    switch (code) {
      case 'error_pose':
        return '내 사진에서 자세를 인식하지 못했어요. 정면을 보고 선 사진으로 바꿔 주세요.';
      case 'error_invalid_src':
        return '내 사진에 상반신이 보여야 해요. 사진을 바꿔 주세요.';
      case 'error_invalid_ref':
        return '옷 사진에서 옷을 찾지 못했어요. 옷 전체가 보이는 정면 사진을 써주세요.';
      case 'error_apply_region_mismatch':
        return '내 사진과 옷 종류가 맞지 않아요. 전신 사진을 등록하거나 옷 종류를 바꿔 주세요.';
      case 'error_multi_person':
        return '사진에 한 사람만 나와야 해요.';
      case 'exceed_max_filesize':
        return '사진이 너무 커요. 더 작은 사진을 써주세요.';
      case 'error_below_min_image_size':
        return '사진이 너무 작아요. 더 큰 사진을 써주세요.';
      case 'error_nsfw_content_detected':
        return '사용할 수 없는 사진이에요. 다른 사진을 써주세요.';
      default:
        return '입어보기에 실패했어요. ($code)';
    }
  }
}
