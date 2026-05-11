/// Shared helpers for building backend-shaped response fixtures.
///
/// All backend responses use the envelope:
///   Success: `{"data": <payload>}`
///   Error:   `{"error": {"message": "...", "code": "...", "statusCode": ...}}`
///
/// Use these helpers to wrap test data in the correct wire format so that
/// integration tests verify the full `fromJson` pipeline against real backend
/// response shapes.
library;

/// Wraps [payload] in the success envelope that `ApiResponse.fromJson`
/// expects: `{"data": <payload>}`.
Map<String, dynamic> dataResponse(Map<String, dynamic> payload) =>
    {'data': payload};

/// Wraps a list [payload] in the success envelope that
/// `apiResponseListFromJson` expects: `{"data": <payload>}`.
Map<String, dynamic> dataListResponse(List<dynamic> payload) =>
    {'data': payload};

/// Builds an error envelope that `ApiResponse.fromJson` expects:
/// `{"error": {"message": ..., "code": ..., "statusCode": ...}}`.
Map<String, dynamic> errorResponse({
  required String message,
  String? code,
  int? statusCode,
}) =>
    {
      'error': {
        'message': message,
        'code': ?code,
        'statusCode': ?statusCode,
      },
    };

/// Wraps a value that should be nested under a key within the `data` envelope.
///
/// Example — backend returns `jsonSuccess({ session })` which becomes
/// `{"data": {"session": {...}}}` on the wire. Call this as:
/// ```dart
/// dataResponse(nestedResponse('session', sessionJson));
/// ```
Map<String, dynamic> nestedResponse(String key, Map<String, dynamic> value) =>
    {key: value};
