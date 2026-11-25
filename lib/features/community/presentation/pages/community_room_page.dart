// lib/features/community/presentation/pages/community_room_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../../chat/domain/entities/message_entity.dart';
import '../../domain/entities/community_entity.dart';
import '../controllers/community_notifier.dart';

class CommunityRoomPage extends StatefulWidget {
  final CommunityEntity community;
  final String currentUserId;
  final String currentUserName;

  const CommunityRoomPage({
    super.key,
    required this.community,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CommunityRoomPage> createState() => _CommunityRoomPageState();
}

class _CommunityRoomPageState extends State<CommunityRoomPage> {
  final CommunityNotifier _notifier = sl<CommunityNotifier>();
  final AuthNotifier _authNotifier = sl<AuthNotifier>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _notifier.listenToCommunityMessages(widget.community.id);
    _notifier.addListener(_errorListener);
  }

  void _errorListener() {
    if (_notifier.errorMessage != null && mounted) {
      final err = _notifier.errorMessage!;
      _notifier.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_errorListener);
    _textController.dispose();
    _scrollController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _notifier.sendTextMessage(
      communityId: widget.community.id,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      text: text,
    );

    _textController.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        _notifier.sendImageMessage(
          communityId: widget.community.id,
          senderId: widget.currentUserId,
          senderName: widget.currentUserName,
          imagePath: image.path,
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAddMemberDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member to Private Group'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Member's Mobile Number",
            hintText: "e.g. +923001234567",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;

              final user = await _authNotifier.findUserByPhoneNumber(phone);
              if (user == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No registered user found with this phone number.')),
                  );
                }
                return;
              }

              final success = await _notifier.addMemberToCommunity(
                communityId: widget.community.id,
                memberId: user.id,
              );

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${user.displayName} to group!')),
                );
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showCommunityInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: widget.community.isPublic ? Colors.blue[100] : Colors.amber[100],
                  child: Icon(
                    widget.community.isPublic ? Icons.public : Icons.lock,
                    size: 32,
                    color: widget.community.isPublic ? Colors.blue[800] : Colors.amber[800],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.community.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.community.memberIds.length} Members • ${widget.community.isPublic ? "Public Group" : "Private Group"}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(widget.community.description, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            if (!widget.community.isPublic && widget.community.adminId == widget.currentUserId)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddMemberDialog();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.community.adminId == widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _showCommunityInfo,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.community.isPublic ? Colors.blue[100] : Colors.amber[100],
                child: Icon(
                  widget.community.isPublic ? Icons.public : Icons.lock,
                  size: 20,
                  color: widget.community.isPublic ? Colors.blue[800] : Colors.amber[800],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.community.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.community.memberIds.length} members',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!widget.community.isPublic && isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Add Member',
              onPressed: _showAddMemberDialog,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showCommunityInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _notifier,
              builder: (context, _) {
                if (_notifier.isLoading && _notifier.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_notifier.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages in this community yet.\nBe the first to start the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _notifier.messages.length,
                  itemBuilder: (context, index) {
                    final message = _notifier.messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.black : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  message.senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            if (message.type == MessageType.image && message.mediaUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: message.mediaUrl!.startsWith('http')
                                    ? Image.network(
                                        message.mediaUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            height: 180,
                                            width: 180,
                                            color: Colors.grey[300],
                                            child: const Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 80),
                                      )
                                    : Image.file(
                                        File(message.mediaUrl!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 80),
                                      ),
                              ),
                            if (message.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.black87),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.community.name}...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
