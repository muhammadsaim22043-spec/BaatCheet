// lib/features/auth/data/datasources/auth_local_data_source.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getUserById(String id);
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber);
  Future<int> countUsersByEmail(String email);
  Future<List<UserModel>> getAllUsers();
  Future<void> saveCurrentSessionId(String userId);
  Future<String?> getCurrentSessionId();
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Isar _isar;
  final FlutterSecureStorage _secureStorage;

  // The key identifier for our secure hardware vault entry
  static const _sessionKey = 'active_user_session_id';

  AuthLocalDataSourceImpl(this._isar, this._secureStorage);

  @override
  Future<void> cacheUser(UserModel user) async {
    // Isar requires all modifications to happen inside a synchronous "transaction" block
    await _isar.writeTxn(() async {
      await _isar.userModels.put(user);
    });
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    // Highly efficient generated query targeting our indexed text ID field
    return await _isar.userModels.filter().idEqualTo(id).findFirst();
  }

  @override
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    return await _isar.userModels.filter().phoneNumberEqualTo(phoneNumber).findFirst();
  }

  @override
  Future<int> countUsersByEmail(String email) async {
    return await _isar.userModels.filter().emailEqualTo(email, caseSensitive: false).count();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return await _isar.userModels.where().findAll();
  }

  @override
  Future<void> saveCurrentSessionId(String userId) async {
    await _secureStorage.write(key: _sessionKey, value: userId);
  }

  @override
  Future<String?> getCurrentSessionId() async {
    return await _secureStorage.read(key: _sessionKey);
  }

  @override
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionKey);
  }
}