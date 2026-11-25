// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );

  @override
  Future<Either<Failure, UserEntity?>> getUserByPhoneNumber(String phoneNumber) async {
    try {
      var userModel = await _localDataSource.getUserByPhoneNumber(phoneNumber);
      userModel ??= await _remoteDataSource.getUserByPhone(phoneNumber);
      return Right(userModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to find user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getUserByEmail(String email) async {
    try {
      // Local Isar doesn't have an email index out of the box so we'll just check remote
      var userModel = await _remoteDataSource.getUserByEmail(email);
      return Right(userModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to find user by email: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getUserById(String id) async {
    try {
      // 1. Search locally first
      var userModel = await _localDataSource.getUserById(id);
      
      // 2. If not found, search in the Cloud
      userModel ??= await _remoteDataSource.getUserById(id);

      return Right(userModel?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to find user by ID: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // 1. Check the secure hardware vault for a logged-in session ID
      final activeId = await _localDataSource.getCurrentSessionId();

      if (activeId == null) {
        // Safe success: no user is logged in yet
        return const Right(null);
      }

      // 2. The local session is only valid if Firebase Auth is signed in as the
      // same user; otherwise every Firestore call would be rejected by the rules
      // (e.g. iOS keychain survived a reinstall, or the token was revoked).
      final firebaseUid = await _remoteDataSource.getSignedInUid();
      if (firebaseUid != activeId) {
        await _localDataSource.clearSession();
        return const Right(null);
      }

      // 3. Fetch their full profile record from Isar, falling back to the cloud
      var userModel = await _localDataSource.getUserById(activeId);
      if (userModel == null) {
        userModel = await _remoteDataSource.getUserById(activeId);
        if (userModel != null) await _localDataSource.cacheUser(userModel);
      }

      // 4. Return the sanitized Domain entity on the Right side
      return Right(userModel?.toEntity());

    } catch (e) {
      return Left(CacheFailure('Failed to read device session storage: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllLocalUsers() async {
    try {
      final users = await _localDataSource.getAllUsers();
      return Right(users.map((u) => u.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to fetch local users: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyPhoneNumber({
    required String phoneNumber,
    String? displayName,
    required void Function(String verificationId) onCodeSent,
    required void Function(UserEntity user) onAutoVerified,
    required void Function(String errorMessage) onError,
  }) async {
    try {
      await _remoteDataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android can verify without the user typing the code. With instant
          // verification codeSent never fires, so we must finish sign-in here.
          final result = await _signInWithCredential(
            credential: credential,
            phoneNumber: phoneNumber,
            displayName: displayName,
          );
          result.fold(
            (failure) => onError(failure.message),
            (user) => onAutoVerified(user),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    String? displayName,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _signInWithCredential(
      credential: credential,
      phoneNumber: phoneNumber,
      displayName: displayName,
    );
  }

  Future<Either<Failure, UserEntity>> _signInWithCredential({
    required AuthCredential credential,
    required String phoneNumber,
    String? displayName,
  }) async {
    try {
      final userCredential = await _remoteDataSource.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Left(AuthFailure("Failed to sign in. User is null."));
      }

      // Profiles are keyed by the Firebase UID (also what the security rules check)
      var userModel = await _remoteDataSource.getUserById(firebaseUser.uid);

      final hasNewName = displayName != null && displayName.isNotEmpty;
      if (userModel == null || (hasNewName && userModel.displayName != displayName)) {
        // Create the profile, or update the name when re-registering
        userModel = UserModel(
          id: firebaseUser.uid,
          phoneNumber: phoneNumber,
          displayName: hasNewName ? displayName : (userModel?.displayName ?? "User"),
          avatarUrl: userModel?.avatarUrl ?? '',
          email: userModel?.email ?? '',
        );
        await _remoteDataSource.uploadUserProfile(userModel);
      }

      // Cache locally
      await _localDataSource.cacheUser(userModel);
      await _localDataSource.saveCurrentSessionId(userModel.id);

      return Right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return const Left(AuthFailure('The code you entered is incorrect.'));
      }
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _remoteDataSource.signInWithEmailPassword(email, password);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const Left(AuthFailure("Failed to sign in. User is null."));
      }

      var userModel = await _remoteDataSource.getUserById(firebaseUser.uid);

      if (userModel == null) {
        // First time login, create missing model
        userModel = UserModel(
          id: firebaseUser.uid,
          phoneNumber: '', // Not required for email login
          displayName: email.split('@')[0], // Default display name from email
          avatarUrl: '',
          email: email,
        );
        await _remoteDataSource.uploadUserProfile(userModel);
      }

      await _localDataSource.cacheUser(userModel);
      await _localDataSource.saveCurrentSessionId(userModel.id);

      return Right(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return const Left(AuthFailure('Invalid email or password.'));
      }
      return Left(AuthFailure(e.message ?? e.code));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await _remoteDataSource.signOut();
    await _localDataSource.clearSession();
  }

}