import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:meep/features/diary/application/diary_controller.dart';
import 'package:meep/features/diary/data/diary_entry.dart';

part 'profile_diary_entries_provider.g.dart';

/// Public diary entries shown on Profile Diary tab, newest first.
@riverpod
Future<List<DiaryEntry>> profileDiaryEntries(Ref ref, String uid) async {
  if (uid.isEmpty) return const [];

  final entries = await ref.read(diaryRepositoryProvider).getPublicEntries(uid);
  final sorted = [...entries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted;
}
