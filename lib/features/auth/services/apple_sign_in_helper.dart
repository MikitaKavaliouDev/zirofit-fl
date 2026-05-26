import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Result returned by [AppleSignInHelper.signIn] when the user successfully
/// authenticates with Apple.
class AppleSignInResult {
  /// The raw identity token (JWT) returned by Apple.
  final String identityToken;

  /// The authorization code (optional).
  final String? authorizationCode;

  /// The raw (unhashed) nonce that was used during the authentication request.
  /// The backend must verify that SHA256([nonce]) matches the nonce hash
  /// embedded in the identity token.
  final String nonce;

  const AppleSignInResult({
    required this.identityToken,
    this.authorizationCode,
    required this.nonce,
  });
}

/// Helper class that encapsulates native Apple Sign In via the
/// `sign_in_with_apple` package.
///
/// For testability, pass a custom [getCredential] function that returns an
/// [AuthorizationCredentialAppleID]. When not provided, the real native
/// implementation via [SignInWithApple.getAppleIDCredential] is used.
class AppleSignInHelper {
  /// Override for [SignInWithApple.getAppleIDCredential], used for testing.
  final Future<AuthorizationCredentialAppleID> Function({
    required List<AppleIDAuthorizationScopes> scopes,
    String? nonce,
  })? getCredential;

  const AppleSignInHelper({this.getCredential});

  /// Presents the native Apple Sign In dialog.
  ///
  /// Returns an [AppleSignInResult] on success, `null` when the user
  /// cancels the flow, and rethrows any other error.
  Future<AppleSignInResult?> signIn() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await (getCredential ??
          SignInWithApple.getAppleIDCredential)(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      if (credential.identityToken == null) {
        throw const AppleSignInException(
          'Apple returned a null identityToken',
        );
      }

      return AppleSignInResult(
        identityToken: credential.identityToken!,
        authorizationCode: credential.authorizationCode,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // User explicitly cancelled the sign-in sheet.
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }
}

/// Exception thrown by [AppleSignInHelper] for non-Apple-authorisation errors.
class AppleSignInException implements Exception {
  final String message;
  const AppleSignInException(this.message);

  @override
  String toString() => 'AppleSignInException: $message';
}
