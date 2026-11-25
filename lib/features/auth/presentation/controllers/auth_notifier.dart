// lib/features/auth/presentation/controllers/auth_notifier.dart

import 'package:flutter/material.dart';
import '../../../../core/utils/string_sanitizer.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// 🔒 STATE DEFINITIONS
/// A strict set of blueprints defining the ONLY four states our login system can experience.
sealed class AuthState {
  const AuthState();
}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);
}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthPhoneOtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final String? displayName;
  /// Set when the entered code was wrong, so the user can retry without
  /// requesting a new SMS.
  final String? errorMessage;
  const AuthPhoneOtpSent({
    required this.verificationId,
    required this.phoneNumber,
    this.displayName,
    this.errorMessage,
  });
}

/// 🎛️ THE CONTROLLER
/// Manages the visual state transitions and drives our Domain operations.
class AuthNotifier extends ChangeNotifier {
  final AuthRepository _authRepository;

  // Start in Loading so the login form doesn't flash while the stored session is checked
  AuthState _state = AuthLoading();
  AuthState get state => _state;

  List<UserEntity> _localAccounts = [];
  List<UserEntity> get localAccounts => _localAccounts;

  AuthNotifier(this._authRepository);

  /// Fetches all users stored on this device
  Future<void> fetchLocalAccounts() async {
    final result = await _authRepository.getAllLocalUsers();
    result.fold(
      (failure) => null, // Silently fail for now
      (users) {
        _localAccounts = users;
        notifyListeners();
      },
    );
  }

  /// Triggers the login sequence
  Future<void> requestPhoneOtp({
    required String phoneNumber,
    String? displayName,
  }) async {
    // Firebase only accepts E.164 numbers, e.g. +923001234567
    final cleanPhone = StringSanitizer.normalizePakistaniPhone(phoneNumber);
    if (cleanPhone == null) {
      _updateState(const AuthError('Invalid Pakistani phone number.'));
      return;
    }

    _updateState(AuthLoading());

    final result = await _authRepository.verifyPhoneNumber(
      phoneNumber: cleanPhone,
      displayName: displayName,
      onAutoVerified: (user) => _updateState(AuthSuccess(user)),
      onCodeSent: (verificationId) {
        _updateState(AuthPhoneOtpSent(
          verificationId: verificationId,
          phoneNumber: cleanPhone,
          displayName: displayName,
        ));
      },
      onError: (errorMessage) {
        _updateState(AuthError(errorMessage));
      },
    );

    result.fold(
      (failure) => _updateState(AuthError(failure.message)),
      (_) => null, // State is updated inside onCodeSent
    );
  }

  Future<void> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    String? displayName,
  }) async {
    _updateState(AuthLoading());

    final result = await _authRepository.signInWithPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      phoneNumber: phoneNumber,
      displayName: displayName,
    );

    result.fold(
      // Stay on the code screen so a typo doesn't force a new SMS
      (failure) => _updateState(AuthPhoneOtpSent(
        verificationId: verificationId,
        phoneNumber: phoneNumber,
        displayName: displayName,
        errorMessage: failure.message,
      )),
      (user) => _updateState(AuthSuccess(user)),
    );
  }

  Future<UserEntity?> findUserByPhoneNumber(String phoneNumber) async {
    // Profiles are stored in E.164, so normalize whatever the user typed
    final cleanPhone = StringSanitizer.normalizePakistaniPhone(phoneNumber);
    if (cleanPhone == null) return null;
    final result = await _authRepository.getUserByPhoneNumber(cleanPhone);
    return result.fold(
      (failure) => null,
      (user) => user,
    );
  }

  Future<UserEntity?> findUserByEmail(String email) async {
    final result = await _authRepository.getUserByEmail(email.trim());
    return result.fold(
      (failure) => null,
      (user) => user,
    );
  }

  Future<UserEntity?> getUserById(String id) async {
    final result = await _authRepository.getUserById(id);
    return result.fold(
      (failure) => null,
      (user) => user,
    );
  }

  /// Checks if a session profile already exists inside the local device hardware
  Future<void> checkExistingSession() async {
    // Also fetch local accounts while checking session
    await fetchLocalAccounts();

    final result = await _authRepository.getCurrentUser();

    result.fold(
          (failure) => _updateState(AuthError(failure.message)),
          (userEntity) {
        if (userEntity != null) {
          _updateState(AuthSuccess(userEntity));
        } else {
          _updateState(AuthInitial());
        }
      },
    );
  }

  void resetState() {
    _updateState(AuthInitial());
  }

  void _updateState(AuthState newState) {
    _state = newState;
    if (newState is AuthInitial) {
      fetchLocalAccounts(); // Refresh accounts list when going back to login
    }
    notifyListeners(); // Force-alerts the Flutter UI framework to redraw the pixels immediately
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _updateState(AuthLoading());

    final result = await _authRepository.signInWithEmailPassword(
      email: email.trim(),
      password: password,
    );

    result.fold(
      (failure) => _updateState(AuthError(failure.message)),
      (user) => _updateState(AuthSuccess(user)),
    );
  }

  Future<void> logout() async {
    _updateState(AuthLoading());

    try {
      // 1. Tell the repository layer to evict the active session key
      await _authRepository.logout();

      // 2. Roll back the state to initial (redirects user automatically to the login form)
      _updateState(AuthInitial());
    } catch (e) {
      // 3. Fallback to an error state if hardware decryption locks up
      _updateState(AuthError(e.toString()));
    }
  }
}


