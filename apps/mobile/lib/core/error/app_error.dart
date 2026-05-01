/// Typed application errors. Throw subclasses, never raw [Exception].
///
/// Repositories convert `FirebaseException`/`PlatformException` into [AppError]
/// at the boundary so business logic and UI deal with one error model.
sealed class AppError implements Exception {
  const AppError({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class UnauthenticatedError extends AppError {
  const UnauthenticatedError({super.message = 'Authentication required'});
}

class ForbiddenError extends AppError {
  ForbiddenError(String action) : super(message: 'Not allowed to $action');
}

class NotFoundError extends AppError {
  NotFoundError(String resource) : super(message: '$resource not found');
}

class ValidationError extends AppError {
  const ValidationError({required super.message, super.cause});
}

class NetworkError extends AppError {
  const NetworkError({super.message = 'Network unavailable', super.cause});
}

class UnexpectedError extends AppError {
  const UnexpectedError({super.message = 'Unexpected error', super.cause});
}
