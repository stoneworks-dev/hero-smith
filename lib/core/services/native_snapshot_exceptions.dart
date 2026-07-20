/// A native backup failure annotated for callers that need actionable import
/// diagnostics. It remains a [FormatException] for compatibility with the
/// existing import API.
class NativeSnapshotException extends FormatException {
  const NativeSnapshotException({
    required this.code,
    required this.fieldPath,
    required String message,
  }) : super(message);

  final String code;
  final String fieldPath;
}

/// A current-schema snapshot that failed structural validation.
class NativeSnapshotValidationException extends NativeSnapshotException {
  const NativeSnapshotValidationException({
    required super.code,
    required super.fieldPath,
    required super.message,
  });
}

/// A write, normalization, or relationship failure that rolled back a native
/// import transaction. [cause] is retained for logs and developer diagnostics.
class NativeSnapshotImportException extends NativeSnapshotException {
  const NativeSnapshotImportException({
    required super.code,
    required super.fieldPath,
    required super.message,
    required this.cause,
  });

  final Object cause;
}
