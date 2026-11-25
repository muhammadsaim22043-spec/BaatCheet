// lib/features/community/domain/repositories/community_repository.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../entities/community_entity.dart';
import '../entities/community_message_entity.dart';

abstract class CommunityRepository {
  Stream<List<CommunityEntity>> watchUserCommunities(String userId);
  Future<Either<Failure, List<CommunityEntity>>> searchPublicCommunities(String query);
  Future<Either<Failure, void>> createCommunity(CommunityEntity community);
  Future<Either<Failure, void>> joinCommunity(String communityId, String userId);
  Future<Either<Failure, void>> addMemberToCommunity(String communityId, String memberId);
  Future<Either<Failure, void>> sendCommunityMessage(CommunityMessageEntity message);
  Stream<List<CommunityMessageEntity>> watchCommunityMessages(String communityId);
  Future<Either<Failure, String>> uploadImage(String filePath);
}
