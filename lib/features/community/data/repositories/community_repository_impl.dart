// lib/features/community/data/repositories/community_repository_impl.dart

import 'dart:async';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/entities/community_message_entity.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_local_data_source.dart';
import '../datasources/community_remote_data_source.dart';
import '../models/community_model.dart';
import '../models/community_message_model.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityLocalDataSource _localDataSource;
  final CommunityRemoteDataSource _remoteDataSource;

  CommunityRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Stream<List<CommunityEntity>> watchUserCommunities(String userId) {
    final controller = StreamController<List<CommunityEntity>>();

    _remoteDataSource.watchUserCommunities(userId).listen(
      (remoteModels) async {
        await _localDataSource.cacheCommunities(remoteModels);
        controller.add(remoteModels.map((m) => m.toEntity()).toList());
      },
      onError: (e) {
        _localDataSource.watchCommunities(userId).listen((localModels) {
          controller.add(localModels.map((m) => m.toEntity()).toList());
        });
      },
    );

    return controller.stream;
  }

  @override
  Future<Either<Failure, List<CommunityEntity>>> searchPublicCommunities(String query) async {
    try {
      final models = await _remoteDataSource.searchPublicCommunities(query);
      return right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return left(CacheFailure('Failed to search communities: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> createCommunity(CommunityEntity community) async {
    try {
      final model = CommunityModel.fromEntity(community);
      await _remoteDataSource.createCommunity(model);
      await _localDataSource.cacheCommunities([model]);
      return right(null);
    } catch (e) {
      return left(CacheFailure('Failed to create community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> joinCommunity(String communityId, String userId) async {
    try {
      await _remoteDataSource.joinCommunity(communityId, userId);
      return right(null);
    } catch (e) {
      return left(CacheFailure('Failed to join community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMemberToCommunity(String communityId, String memberId) async {
    try {
      await _remoteDataSource.addMemberToCommunity(communityId, memberId);
      return right(null);
    } catch (e) {
      return left(CacheFailure('Failed to add member to community: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendCommunityMessage(CommunityMessageEntity message) async {
    try {
      final model = CommunityMessageModel.fromEntity(message);
      await _remoteDataSource.sendCommunityMessage(model);
      await _localDataSource.cacheMessages([model]);
      return right(null);
    } catch (e) {
      return left(CacheFailure('Failed to send community message: $e'));
    }
  }

  @override
  Stream<List<CommunityMessageEntity>> watchCommunityMessages(String communityId) {
    final controller = StreamController<List<CommunityMessageEntity>>();

    _remoteDataSource.watchCommunityMessages(communityId).listen(
      (remoteModels) async {
        await _localDataSource.cacheMessages(remoteModels);
        controller.add(remoteModels.map((m) => m.toEntity()).toList());
      },
      onError: (e) {
        _localDataSource.watchMessages(communityId).listen((localModels) {
          controller.add(localModels.map((m) => m.toEntity()).toList());
        });
      },
    );

    return controller.stream;
  }

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      final downloadUrl = await _remoteDataSource.uploadImage(file);
      return right(downloadUrl);
    } catch (e) {
      return left(CacheFailure('Failed to upload image: $e'));
    }
  }
}
