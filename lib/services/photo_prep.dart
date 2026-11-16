import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 전신 사진을 엔진에 보내기 전에 정리한다.
/// 1) 사진 방향 바로잡기 2) 흰 테두리 잘라내기 3) 가로 사진이면 가운데를 세로(3:4)로 자르기
/// 실패하면 원본 경로를 그대로 돌려준다.
Future<String> preparePersonPhoto(String path) async {
  try {
    return await compute(_prepare, path);
  } catch (_) {
    return path;
  }
}

String _prepare(String path) {
  final img.Image? decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) {
    return path;
  }
  img.Image image = img.bakeOrientation(decoded);
  image = _trimWhiteBorder(image);

  const double target = 3 / 4;
  if (image.width / image.height > target) {
    final int w = (image.height * target).round();
    final int x = ((image.width - w) / 2).round();
    image = img.copyCrop(image, x: x, y: 0, width: w, height: image.height);
  }
  if (image.height > 1600) {
    image = img.copyResize(image, height: 1600);
  }

  final File out = File('${Directory.systemTemp.path}/person_${DateTime.now().millisecondsSinceEpoch}.jpg');
  out.writeAsBytesSync(img.encodeJpg(image, quality: 92));
  return out.path;
}

bool _isWhite(img.Pixel p) => p.r > 232 && p.g > 232 && p.b > 232;

bool _rowWhite(img.Image im, int y) {
  int white = 0;
  int total = 0;
  for (int x = 0; x < im.width; x += 4) {
    total++;
    if (_isWhite(im.getPixel(x, y))) {
      white++;
    }
  }
  return white >= total * 0.97;
}

bool _colWhite(img.Image im, int x) {
  int white = 0;
  int total = 0;
  for (int y = 0; y < im.height; y += 4) {
    total++;
    if (_isWhite(im.getPixel(x, y))) {
      white++;
    }
  }
  return white >= total * 0.97;
}

/// 가장자리의 흰 테두리만 잘라낸다. 각 방향 최대 15%까지만.
img.Image _trimWhiteBorder(img.Image im) {
  final int maxY = (im.height * 0.15).round();
  final int maxX = (im.width * 0.15).round();
  int top = 0;
  int bottom = 0;
  int left = 0;
  int right = 0;
  while (top < maxY && _rowWhite(im, top)) {
    top++;
  }
  while (bottom < maxY && _rowWhite(im, im.height - 1 - bottom)) {
    bottom++;
  }
  while (left < maxX && _colWhite(im, left)) {
    left++;
  }
  while (right < maxX && _colWhite(im, im.width - 1 - right)) {
    right++;
  }
  if (top + bottom + left + right == 0) {
    return im;
  }
  // 테두리 바로 안쪽의 얇은 그림자 선까지 함께 잘라낸다.
  const int pad = 6;
  if (top > 0) top += pad;
  if (bottom > 0) bottom += pad;
  if (left > 0) left += pad;
  if (right > 0) right += pad;
  final int w = im.width - left - right;
  final int h = im.height - top - bottom;
  if (w < im.width * 0.5 || h < im.height * 0.5) {
    return im;
  }
  return img.copyCrop(im, x: left, y: top, width: w, height: h);
}
