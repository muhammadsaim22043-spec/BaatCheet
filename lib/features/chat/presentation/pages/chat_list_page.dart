// lib/features/chat/presentation/pages/chat_list_page.dart

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/string_sanitizer.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart'; // 🔌 Adjust this import pathway if needed!
import '../../../auth/domain/entities/user_entity.dart';
import '../../../community/presentation/pages/community_list_page.dart';
import '../controllers/chat_notifier.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  final String currentUserId;

  const ChatListPage({super.key, required this.currentUserId});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatNotifier _chatNotifier = sl<ChatNotifier>();
  final AuthNotifier _authNotifier = sl<AuthNotifier>();

  // Friend profiles fetched from Firestore, keyed by user ID
  final Map<String, UserEntity> _friends = {};
  final Set<String> _pendingLookups = {};

  @override
  void initState() {
    super.initState();
    _chatNotifier.addListener(_resolveFriendProfiles);
    // 🔒 Pass the active user ID down so they only see their own direct messages
    _chatNotifier.listenToChatThreads(widget.currentUserId);
  }

  @override
  void dispose() {
    _chatNotifier.removeListener(_resolveFriendProfiles);
    _chatNotifier.dispose();
    super.dispose();
  }

  String _friendIdOf(List<String> participantIds) => participantIds.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => widget.currentUserId,
      );

  /// Loads the display name of every chat partner we haven't looked up yet.
  void _resolveFriendProfiles() {
    for (final chat in _chatNotifier.chatThreads) {
      final friendId = _friendIdOf(chat.participantIds);
      if (_friends.containsKey(friendId) || !_pendingLookups.add(friendId)) continue;

      _authNotifier.getUserById(friendId).then((user) {
        if (user != null && mounted) {
          setState(() => _friends[friendId] = user);
        }
      }).whenComplete(() => _pendingLookups.remove(friendId));
    }
  }

  /// Action dialog updated to ask for Mobile Number / Email
  void _createNewChatDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Friend's Phone or Email",
            hintText: "e.g. +923001234567 or john@example.com",
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
              final target = controller.text.trim();
              if (target.isEmpty) return;

              // 1. Check if user exists by email or phone
              final isEmail = target.contains('@');
              final friend = isEmail
                  ? await _authNotifier.findUserByEmail(target)
                  : await _authNotifier.findUserByPhoneNumber(target);
              
              if (friend == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No registered user found with this ${isEmail ? 'email' : 'phone number'}.')),
                  );
                }
                return;
              }

              if (friend.id == widget.currentUserId) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You cannot chat with yourself.')),
                  );
                }
                return;
              }

              if (context.mounted) {
                // Grab the navigator first: the dialog's context is gone once it's popped
                final navigator = Navigator.of(context);
                navigator.pop();

                _friends[friend.id] = friend;
                final sortedIds = [widget.currentUserId, friend.id]..sort();
                final generatedChatId = 'chat_${sortedIds.join('_')}';

                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => ChatRoomPage(
                      chatId: generatedChatId,
                      receiverId: friend.id,
                      receiverName: friend.displayName, // 🏷️ Pass name
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('CHAT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: [
                Tab(text: 'Chats'),
                Tab(text: 'Communities'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Direct Message Threads
            Scaffold(
              backgroundColor: Colors.white,
              body: ListenableBuilder(
                listenable: _chatNotifier,
                builder: (context, child) {
                  if (_chatNotifier.isLoading && _chatNotifier.chatThreads.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_chatNotifier.chatThreads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alternate_email, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No messages yet', style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Tap the blue pen to start a new chat thread', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _chatNotifier.chatThreads.length,
                    itemBuilder: (context, index) {
                      final chat = _chatNotifier.chatThreads[index];
                      final friendId = _friendIdOf(chat.participantIds);

                      final friend = _friends[friendId] ??
                          UserEntity(id: friendId, displayName: 'Loading...', phoneNumber: '', avatarURL: '', email: '');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                              StringSanitizer.initial(friend.displayName),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)
                          ),
                        ),
                        title: Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        trailing: Icon(Icons.camera_alt_outlined, color: Colors.grey[400]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomPage(
                                chatId: chat.id,
                                receiverId: friendId,
                                receiverName: _friends[friendId]?.displayName ?? friendId,
                                currentUserId: widget.currentUserId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: _createNewChatDialog,
                backgroundColor: Colors.blue,
                elevation: 2,
                child: const Icon(Icons.create, color: Colors.white),
              ),
            ),

            // Tab 2: Communities / Group Chats
            CommunityListPage(
              currentUserId: widget.currentUserId,
              currentUserName: (_authNotifier.state is AuthSuccess)
                  ? (_authNotifier.state as AuthSuccess).user.displayName
                  : 'Member',
            ),
          ],
        ),
      ),
    );
  }
}