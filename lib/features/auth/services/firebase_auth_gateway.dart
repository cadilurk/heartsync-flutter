import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_exception.dart';

/// Outcome of starting (or auto-completing) a phone verification flow.
sealed class PhoneVerificationOutcome {}

/// An OTP code was sent to the device; [verificationId] must be paired with
/// the user-entered SMS code to complete sign-in.
class PhoneOtpSent extends PhoneVerificationOutcome {
  final String verificationId;
  final int? forceResendingToken;

  PhoneOtpSent(this.verificationId, this.forceResendingToken);
}

/// The phone number was verified automatically by the platform (e.g. SMS
/// auto-retrieval on Android) without the user needing to enter a code.
class PhoneAutoVerified extends PhoneVerificationOutcome {
  final String firebaseIdToken;

  PhoneAutoVerified(this.firebaseIdToken);
}

/// Thrown by [FirebaseAuthGateway.signInWithGoogle] when the user backs out
/// of the account picker — the classic `google_sign_in` v6 API reports this
/// as a plain `null` result rather than an exception, so this type exists to
/// let [AuthProvider] tell "user canceled" apart from a real failure.
class GoogleSignInCanceled implements Exception {}

/// The ONLY place in the app that directly touches the `firebase_auth`/
/// `google_sign_in` SDKs. Everything else (namely [AuthProvider]) composes
/// this class instead of importing those packages directly.
class FirebaseAuthGateway {
  static const String _webClientId =
      '236247833644-j54ban2jiv8ecvdrhqq2hkffiqmts05h.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: const ['email', 'profile'],
  );

  /// Runs the interactive Google sign-in flow and returns a Firebase ID
  /// token ready to send to our backend's `/auth/firebase` endpoint.
  ///
  /// Throws [GoogleSignInCanceled] if the user backs out of the account
  /// picker, or [ApiException] if a token comes back null.
  Future<String> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw GoogleSignInCanceled();
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseIdToken = await userCredential.user?.getIdToken();
    if (firebaseIdToken == null) {
      throw const ApiException(
        code: 'FIREBASE_TOKEN_INVALID',
        message: 'Firebase idToken missing',
      );
    }
    return firebaseIdToken;
  }

  /// Starts (or resends) phone number verification. Completes with either a
  /// [PhoneOtpSent] (caller must prompt the user for the SMS code) or a
  /// [PhoneAutoVerified] (platform verified silently, e.g. Android
  /// SMS auto-retrieval).
  Future<PhoneVerificationOutcome> sendPhoneCode(
    String phoneNumber, {
    int? forceResendingToken,
  }) {
    final completer = Completer<PhoneVerificationOutcome>();
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        if (completer.isCompleted) return;
        try {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null) {
            completer.complete(PhoneAutoVerified(idToken));
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) completer.complete(PhoneOtpSent(verificationId, resendToken));
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(PhoneOtpSent(verificationId, null));
      },
    );
    return completer.future;
  }

  /// Confirms a user-entered SMS code against a prior [sendPhoneCode] call
  /// and returns a Firebase ID token ready to send to our backend.
  Future<String> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) {
      throw const ApiException(
        code: 'FIREBASE_TOKEN_INVALID',
        message: 'Firebase idToken missing',
      );
    }
    return idToken;
  }
}
