import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';

Future<void> recordJob(
  BuildContext context, {
  required String tool,
  required String title,
  String detail = '',
}) async {
  final firestore = context.read<FirestoreService?>();
  final messenger = ScaffoldMessenger.of(context);
  if (firestore == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('데모 모드라 이 작업은 화면에만 남아요')),
    );
    return;
  }
  try {
    await firestore.addData('jobs', {
      'tool': tool,
      'title': title,
      'detail': detail,
    });
    messenger.showSnackBar(
      const SnackBar(content: Text('Firestore에 작업을 기록했어요')),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('기록 실패: $e')));
  }
}
