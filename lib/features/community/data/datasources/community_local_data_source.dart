// lib/features/community/data/datasources/community_local_data_source.dart

import 'package:isar/isar.dart';
import '../models/community_model.dart';
import '../models/community_message_model.dart';

abstract class CommunityLocalDataSource {
  Future<void> cacheCommunities(List<CommunityModel> communities);
  Stream<List<CommunityModel>> watchCommunities(String userId);
  Future<void> cacheMessages(List<CommunityMessageModel> messages);
  Stream<List<CommunityMessageModel>> watchMessages(String communityId);
}

class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  final Isar _isar;

  CommunityLocalDataSourceImpl(this._isar);

  @override
  Future<void> cacheCommunities(List<CommunityModel> communities) async {
    await _isar.writeTxn(() async {
      await _isar.communityModels.putAll(communities);
    });
  }

  @override
  Stream<List<CommunityModel>> watchCommunities(String userId) {
    return _isar.communityModels
        .filter()
        .memberIdsElementEqualTo(userId)
        .watch(fireImmediately: true);
  }

  @override
  Future<void> cacheMessages(List<CommunityMessageModel> messages) async {
    await _isar.writeTxn(() async {
      await _isar.communityMessageModels.putAll(messages);
    });
  }

  @override
  Stream<List<CommunityMessageModel>> watchMessages(String communityId) {
    return _isar.communityMessageModels
        .filter()
        .communityIdEqualTo(communityId)
        .sortByTimestamp()
        .watch(fireImmediately: true);
  }
}
