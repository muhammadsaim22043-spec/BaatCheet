// lib/core/di/injection_container.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_notifier.dart';
import '../../features/chat/data/datasources/chat_local_data_source.dart';
import '../../features/chat/data/datasources/chat_remote_data_source.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/presentation/controllers/chat_notifier.dart';
import '../../features/chat/data/models/chat_model.dart';
import '../../features/chat/data/models/message_model.dart';
import '../../features/community/data/datasources/community_local_data_source.dart';
import '../../features/community/data/datasources/community_remote_data_source.dart';
import '../../features/community/data/models/community_message_model.dart';
import '../../features/community/data/models/community_model.dart';
import '../../features/community/data/repositories/community_repository_impl.dart';
import '../../features/community/domain/repositories/community_repository.dart';
import '../../features/community/presentation/controllers/community_notifier.dart';
import '../../features/ai/data/services/ai_service.dart';
// 'sl' stands for Service Locator. This is our central app registry.
final sl = GetIt.instance;

/// This function runs the millisecond our app starts up,
/// registering our tools, data sources, and repositories into memory.
Future<void> initDependencies() async {

  // ─── 1. EXTERNAL CORE TOOLS ───
  // Secure Storage instance for encrypted hardware storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Firebase Firestore instance
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Firebase Auth instance
  sl.registerLazySingleton(() => FirebaseAuth.instance);

  // Supabase Client instance for Storage
  sl.registerLazySingleton(() => Supabase.instance.client);

  // 🤖 AI Service
  sl.registerLazySingleton(() => AIService());

  // Initialize and register Isar Database
  final dir = await getApplicationDocumentsDirectory();
  // ⚠️ Update the Isar.open block inside lib/core/di/injection_container.dart

  // Open the Isar database instance with ALL our feature collection blueprints
  final isar = await Isar.open(
    [
      UserModelSchema,
      MessageModelSchema, // 🔌 Added
      ChatModelSchema,    // 🔌 Added
      CommunityModelSchema,
      CommunityMessageModelSchema,
    ],
    directory: dir.path,
  );
  sl.registerSingleton<Isar>(isar);

  // ─── 2. DATA SOURCES ───
  // We supply 'sl()' inside the constructor. GetIt will automatically
  // look at its registry, find Isar and SecureStorage, and inject them here!
  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(sl(), sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl(), sl()),
  );

  // ─── 3. REPOSITORIES ───
  // Registers our implementation block under the abstract Domain contract rule
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      sl(), // AuthLocalDataSource
      sl(), // AuthRemoteDataSource
    ),
  );
  sl.registerLazySingleton(() => AuthNotifier(sl()));

  sl.registerLazySingleton<ChatLocalDataSource>(
        () => ChatLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ChatRemoteDataSource>(
        () => ChatRemoteDataSourceImpl(sl(), sl()),
  );

  // ─── CHAT FEATURE REPOSITORIES ───
  sl.registerLazySingleton<ChatRepository>(
        () => ChatRepositoryImpl(sl(), sl(), sl()),
  );

  sl.registerFactory(() => ChatNotifier(sl()));

  // ─── COMMUNITY FEATURE ───
  sl.registerLazySingleton<CommunityLocalDataSource>(
        () => CommunityLocalDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<CommunityRemoteDataSource>(
        () => CommunityRemoteDataSourceImpl(sl(), sl()),
  );

  sl.registerLazySingleton<CommunityRepository>(
        () => CommunityRepositoryImpl(sl(), sl()),
  );

  sl.registerFactory(() => CommunityNotifier(sl()));
}