/// Typed application errors. Throw subclasses, never raw [Exception].
///
/// Repositories convert `FirebaseException`/`PlatformException` into [AppError]
/// at the boundary so business logic and UI deal with one error model.
sealed class AppError implements Exception {
  const AppError({required this.message, this.code, this.cause});

  final String message;

  /// Stable machine-readable identifier — handy for analytics / cross-stack
  /// parity with the TS `AppError.code`. Optional; defaults to null.
  final String? code;
  final Object? cause;

  /// Wrap an arbitrary thrown object into an [AppError]. Pass-through if [e]
  /// already is an [AppError]; otherwise wrap in [UnexpectedError] with the
  /// given Vietnamese fallback message.
  ///
  /// Use this in controllers to collapse the standard
  /// `try { ... } on AppError catch (e) { ... } catch (_) { ... }` boilerplate.
  static AppError fromUnknown(
    Object e, {
    String fallback = 'Đã có lỗi xảy ra',
  }) {
    if (e is AppError) return e;
    return UnexpectedError(message: fallback, cause: e);
  }

  @override
  String toString() =>
      code == null ? '$runtimeType: $message' : '$runtimeType[$code]: $message';
}

class UnauthenticatedError extends AppError {
  const UnauthenticatedError({
    super.message = 'Authentication required',
    super.code,
    super.cause,
  });
}

class ForbiddenError extends AppError {
  ForbiddenError(String action) : super(message: 'Not allowed to $action');
}

class NotFoundError extends AppError {
  NotFoundError(String resource) : super(message: '$resource not found');
}

class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.cause,
  });
}

class NetworkError extends AppError {
  const NetworkError({
    super.message = 'Network unavailable',
    super.code,
    super.cause,
  });
}

class UnexpectedError extends AppError {
  const UnexpectedError({
    super.message = 'Unexpected error',
    super.code,
    super.cause,
  });
}

/// User-initiated cancel (e.g. closed the Google Sign-In dialog).
///
/// Controllers should treat this as a silent no-op: reset `isLoading` and
/// leave `errorMessage` null. Never surface this to the UI as a toast/snackbar.
class OperationCancelledError extends AppError {
  const OperationCancelledError({
    super.message = 'Đã huỷ',
    super.cause,
  }) : super(code: 'cancelled');
}
