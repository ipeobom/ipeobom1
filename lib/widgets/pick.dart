import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

final ImagePicker _picker = ImagePicker();

/// 갤러리/카메라 선택 후 사진 경로를 돌려준다. 취소하면 null.
Future<String?> pickPhoto(BuildContext context) async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );
  if (source == null) {
    return null;
  }
  try {
    final XFile? file = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 90);
    return file?.path;
  } catch (_) {
    if (context.mounted) {
      showMsg(context, '사진을 불러오지 못했어요. 다시 시도해 주세요.');
    }
    return null;
  }
}
