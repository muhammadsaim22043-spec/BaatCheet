// lib/features/community/data/datasources/community_remote_data_source.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_model.dart';
import '../models/community_message_model.dart';

abstract class CommunityRemoteDataSource {
  Stream<List<CommunityModel>> watchUserCommunities(String userId);
  Future<List<CommunityModel>> searchPublicCommunities(String query);
  Future<void> createCommunity(CommunityModel community);
  Future<void> joinCommunity(String communityId, String userId);
  Future<void> addMemberToCommunity(String communityId, String memberId);
  Future<void> sendCommunityMessage(CommunityMessageModel message);
  Stream<List<CommunityMessageModel>> watchCommunityMessages(String communityId);
  Future<String> uploadImage(File imageFile);
}

class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final FirebaseFirestore _firestore;
  final SupabaseClient _supabase;

  CommunityRemoteDataSourceImpl(this._firestore, this._supabase);

  @override
  Stream<List<CommunityModel>> watchUserCommunities(String userId) {
    return _firestore
        .collection('communities')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityModel.fromFirestore(doc.data()))
            .toList()
          ..sort((a, b) {
            final tA = a.lastMessageTime ?? a.createdAt;
            final tB = b.lastMessageTime ?? b.createdAt;
            return tB.compareTo(tA);
          }));
  }

  @override
  Future<List<CommunityModel>> searchPublicCommunities(String query) async {
    final snapshot = await _firestore
        .collection('communities')
        .where('isPublic', isEqualTo: true)
        .get();

    final q = query.toLowerCase().trim();
    return snapshot.docs
        .map((doc) => CommunityModel.fromFirestore(doc.data()))
        .where((c) => c.name.toLowerCase().contains(q) || c.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<void> createCommunity(CommunityModel community) async {
    await _firestore
        .collection('communities')
        .doc(community.id)
        .set(community.toJson());
  }

  @override
  Future<void> joinCommunity(String communityId, String userId) async {
    await _firestore.collection('communities').doc(communityId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> addMemberToCommunity(String communityId, String memberId) async {
    await _firestore.collection('communities').doc(communityId).update({
      'memberIds': FieldValue.arrayUnion([memberId]),
    });
  }

  @override
  Future<void> sendCommunityMessage(CommunityMessageModel message) async {
    final batch = _firestore.batch();

    final msgRef = _firestore.collection('community_messages').doc(message.id);
    batch.set(msgRef, {
      'id': message.id,
      'communityId': message.communityId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'text': message.text,
      'type': message.type,
      'mediaUrl': message.mediaUrl,
      'timestamp': message.timestamp.toUtc().toIso8601String(),
    });

    final commRef = _firestore.collection('communities').doc(message.communityId);
    batch.update(commRef, {
      'lastMessage': message.type == 'image' ? '📷 Photo' : message.text,
      'lastMessageTime': message.timestamp.toUtc().toIso8601String(),
    });

    await batch.commit();
  }

  @override
  Stream<List<CommunityMessageModel>> watchCommunityMessages(String communityId) {
    return _firestore
        .collection('community_messages')
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMessageModel.fromFirestore(doc.data()))
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
  }

  @override
  Future<String> uploadImage(File imageFile) async {
    final fileName =
        'comm_img_${DateTime.now().millisecondsSinceEpoch}_${_firestore.collection('community_messages').doc().id}.jpg';

    try {
      await _supabase.storage.from('CHAT-IMAGES').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('CHAT-IMAGES').getPublicUrl(fileName);
    } catch (_) {
      await _supabase.storage.from('chat-images').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('chat-images').getPublicUrl(fileName);
    }
  }
}
