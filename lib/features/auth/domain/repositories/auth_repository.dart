// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_entity.dart';

/// This is a strict contract outlining what our Authentication system must do.
/// The actual database code (Isar) will fill in these blanks later in the Data Layer.
abstract class AuthRepository {

  Future<Either<Failure, UserEntity?>> getUserByPhoneNumber(String phoneNumber);
  Future<Either<Failure, UserEntity?>> getUserByEmail(String email);
  Future<Either<Failure, UserEntity?>> getUserById(String id);

  /// Checks the device's secure storage to see if a user is already logged in.
  /// Returns null on the Right if no active session exists.
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, List<UserEntity>>> getAllLocalUsers();
  /// [onAutoVerified] fires when Android verifies the SMS automatically
  /// (instant verification / auto-retrieval) and the user is already signed in.
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    String? displayName,
    required void Function(String verificationId) onCodeSent,
    required void Function(UserEntity user) onAutoVerified,
    required void Function(String errorMessage) onError,
  });

  Future<Either<Failure, UserEntity>> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    String? displayName,
  });

  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> logout();
}