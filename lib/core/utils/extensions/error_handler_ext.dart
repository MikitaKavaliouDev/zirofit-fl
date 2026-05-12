/// Formats an [error] (typically from an HTTP response or exception) into a
/// user-friendly message by mapping known status codes and stripping common
/// technical prefixes.
String formatApiError(dynamic error) {
  final message = error.toString();

  // Strip common technical prefixes.
  String cleaned = message
      .replaceAll('Server Error: ', '')
      .replaceAll('The operation couldn\'t be completed. ', '');

  // Map known HTTP status codes and keywords.
  if (cleaned.contains('400') || cleaned.contains('Bad Request')) {
    return 'Please check your information and try again.';
  }
  if (cleaned.contains('401') || cleaned.contains('Unauthorized')) {
    return 'Session expired. Please log in again.';
  }
  if (cleaned.contains('403') || cleaned.contains('Forbidden')) {
    return 'You don\'t have permission to perform this action.';
  }
  if (cleaned.contains('404') || cleaned.contains('Not Found')) {
    return 'The requested information could not be found.';
  }
  if (cleaned.contains('500') || cleaned.contains('Internal Server Error')) {
    return 'Our servers are having trouble. Please try again in a few minutes.';
  }
  if (cleaned.contains('offline') ||
      cleaned.contains('network connection') ||
      cleaned.contains('Connection refused')) {
    return 'It looks like you\'re offline. Please check your connection.';
  }

  // If it still contains "Error XYZ: ...", strip the prefix.
  final errorPrefixMatch = RegExp(r'^Error\s+\w+:\s+').firstMatch(cleaned);
  if (errorPrefixMatch != null) {
    return cleaned.substring(errorPrefixMatch.end);
  }

  // Default fallback for empty or cryptic messages.
  if (cleaned.isEmpty || cleaned.contains('ErrorDomain')) {
    return 'An unexpected error occurred. Please try again.';
  }

  return cleaned;
}
