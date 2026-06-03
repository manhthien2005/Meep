import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:meep/core/error/app_error.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';

/// DEBUG ONLY — render chi tiết error (type, code, message, hint) cho user
/// screenshot khi diagnose production issue. Tap "Copy" → clipboard.
///
/// Áp dụng cho diagnose "Không tải được tin nhắn" — show Firebase error code
/// để biết PERMISSION_DENIED vs UNAVAILABLE vs FAILED_PRECONDITION...
///
/// Sau khi root cause confirmed, replace bằng generic message production.
class DebugErrorView extends StatelessWidget {
  const DebugErrorView({
    super.key,
    required this.error,
    required this.context_,
    this.stackTrace,
  });

  /// Error object captured từ AsyncValue.error.
  final Object error;

  /// Tên context để dễ phân biệt: "Inbox", "Chat 1-1", "Group chat".
  // ignore: library_private_types_in_public_api
  final String context_;

  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final details = _extractDetails(error);
    // Log lại 1 lần nữa lúc render để chắc chắn ra console.
    developer.log(
      '[$context_] error display: ${details.summary}',
      name: 'chat-debug',
      error: error,
      stackTrace: stackTrace,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lỗi: $context_',
            style: AppTextStyles.baseBold.copyWith(color: AppColors.error800),
          ),
          const SizedBox(height: 12),
          _DebugRow(label: 'Type', value: details.type),
          _DebugRow(label: 'Code', value: details.code ?? '—'),
          _DebugRow(label: 'Message', value: details.message),
          if (details.plugin != null)
            _DebugRow(label: 'Plugin', value: details.plugin!),
          if (details.hint != null) ...[
            const SizedBox(height: 8),
            Text(
              'Gợi ý:',
              style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw400),
            ),
            const SizedBox(height: 4),
            Text(
              details.hint!,
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw500),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: details.fullDump));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy error details')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy details'),
          ),
        ],
      ),
    );
  }

  _ErrorDetails _extractDetails(Object e) {
    if (e is FirebaseException) {
      return _ErrorDetails(
        type: 'FirebaseException',
        code: e.code,
        message: e.message ?? '(no message)',
        plugin: e.plugin,
        hint: _firebaseHint(e.code),
        fullDump: 'FirebaseException\n'
            'plugin: ${e.plugin}\n'
            'code: ${e.code}\n'
            'message: ${e.message}\n'
            'stack: $stackTrace',
      );
    }
    if (e is AppError) {
      return _ErrorDetails(
        type: e.runtimeType.toString(),
        code: e.code,
        message: e.message,
        plugin: null,
        hint: _appErrorHint(e),
        fullDump: 'AppError(${e.runtimeType})\n'
            'code: ${e.code}\n'
            'message: ${e.message}\n'
            'cause: ${e.cause}\n'
            'stack: $stackTrace',
      );
    }
    return _ErrorDetails(
      type: e.runtimeType.toString(),
      code: null,
      message: e.toString(),
      plugin: null,
      hint: null,
      fullDump: '${e.runtimeType}: $e\nstack: $stackTrace',
    );
  }

  String? _firebaseHint(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Firestore rules deny request. Check rules deployed?\n'
            '- /conversations read: cần `request.auth.uid in resource.data.participantIds`\n'
            '- Field thiếu: status, participantIds';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Network issue hoặc Firestore offline. Check kết nối + emulator host.';
      case 'failed-precondition':
        return 'Compound query missing index. Check Firestore Console → Indexes.';
      case 'not-found':
        return 'Doc/collection không tồn tại.';
      default:
        return null;
    }
  }

  String? _appErrorHint(AppError e) {
    if (e is ForbiddenError) {
      return 'AppError mapped từ permission-denied. Same hint như FirebaseException.';
    }
    if (e is NetworkError) {
      return 'AppError mapped từ network failure.';
    }
    return null;
  }
}

class _ErrorDetails {
  _ErrorDetails({
    required this.type,
    required this.code,
    required this.message,
    required this.plugin,
    required this.hint,
    required this.fullDump,
  });

  final String type;
  final String? code;
  final String message;
  final String? plugin;
  final String? hint;
  final String fullDump;

  String get summary => '$type code=$code msg=$message';
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.smRegular.copyWith(color: AppColors.bw400),
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.smSemiBold.copyWith(color: AppColors.bw300),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.smRegular.copyWith(color: AppColors.bw100),
            ),
          ],
        ),
      ),
    );
  }
}
