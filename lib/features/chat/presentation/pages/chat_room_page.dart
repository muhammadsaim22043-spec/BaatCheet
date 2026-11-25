// lib/features/chat/presentation/pages/chat_room_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/string_sanitizer.dart';
import '../../domain/entities/message_entity.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../controllers/chat_notifier.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName; // 🏷️ Added
  final String currentUserId;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName, // 🏷️ Added
    required this.currentUserId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatNotifier _chatNotifier = sl<ChatNotifier>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late String _displayName; // 🏷️ To store fetched name

  @override
  void initState() {
    super.initState();
    _displayName = widget.receiverName;
    
    // 🏷️ If we were only given a placeholder, fetch the real name from the cloud
    if (_displayName.isEmpty || _displayName == widget.receiverId) {
      _fetchReceiverName();
    }
    
    // Open a persistent stream to watch database messages for this thread
    _chatNotifier.listenToMessages(widget.chatId);
    
    // 🖋️ Mark incoming messages as read
    _chatNotifier.markMessagesAsRead(widget.chatId, widget.currentUserId);

    // 🔔 Listen for new messages and errors
    _chatNotifier.addListener(_notifierListener);
  }

  void _notifierListener() {
    if (mounted) {
      _chatNotifier.markMessagesAsRead(widget.chatId, widget.currentUserId);
      if (_chatNotifier.errorMessage != null) {
        final err = _chatNotifier.errorMessage!;
        _chatNotifier.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchReceiverName() async {
    final authNotifier = sl<AuthNotifier>();
    final user = await authNotifier.getUserById(widget.receiverId);
    if (user != null && mounted) {
      setState(() {
        _displayName = user.displayName;
      });
    }
  }

  @override
  void dispose() {
    _chatNotifier.removeListener(_notifierListener);
    _textController.dispose();
    _scrollController.dispose();
    _chatNotifier.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Links are sent as text and rendered tappable in the bubble
    _chatNotifier.sendTextMessage(
      receiverId: widget.receiverId,
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
        _chatNotifier.sendImageMessage(
          receiverId: widget.receiverId,
          imagePath: image.path,
        );
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚫 Remove left back arrow
        titleSpacing: 0,
        elevation: 0.5, // Subtle bottom line for app bar
        title: InkWell(
          onTap: () async {
            final authNotifier = sl<AuthNotifier>();
            final friend = await authNotifier.getUserById(widget.receiverId);
            if (friend != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(user: friend),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: Text(StringSanitizer.initial(_displayName),
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Active now',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.normal)),
                ],
              ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.local_phone_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}),
          // ➡️ Back button moved to top right
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: Colors.white, // Pure clean background
      body: Stack(
        children: [
          Column(
            children: [
              // ⚠️ ERROR DISPLAY (Helps find Missing Index issues)
              ListenableBuilder(
                listenable: _chatNotifier,
                builder: (context, _) {
                  if (_chatNotifier.errorMessage != null) {
                    return Container(
                      color: Colors.red[50],
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "Sync Error: ${_chatNotifier.errorMessage}",
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // 💬 INSTAGRAM GRADIENT MESSAGES LIST
              Expanded(
                child: ListenableBuilder(
                  listenable: _chatNotifier,
                  builder: (context, child) {
                    final messageList = _chatNotifier.messages;

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messageList.length,
                      itemBuilder: (context, index) {
                        final message = messageList[index];
                        final isAI = message.senderId == 'ai_bot';
                        final isMe = message.senderId == widget.currentUserId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              // ✨ Instagram Gradient Logic
                              gradient: isMe
                                  ? const LinearGradient(
                                colors: [Color(0xFFB135A4), Color(0xFF4364F7)], // Vibrant Purple to Blue Instagram aesthetic
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : null,
                              color: isMe
                                  ? null
                                  : isAI
                                      ? Colors.blue[50]
                                      : Colors.grey[100], // Soft gray for received bubbles
                              border: isAI ? Border.all(color: Colors.blue[200]!) : null,
                              borderRadius: BorderRadius.circular(20), // Fully uniform pill shapes
                            ),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAI)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.smart_toy, size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI Assistant',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ],
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
                                                height: 200,
                                                width: 200,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                    child: CircularProgressIndicator()),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image, size: 100),
                                          )
                                        : Image.file(
                                            File(message.mediaUrl!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image, size: 100),
                                          ),
                                  ),
                                if (message.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: InkWell(
                                      onTap: message.text.startsWith('http')
                                          ? () async {
                                              final url = Uri.tryParse(message.text);
                                              if (url == null) return;
                                              final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
                                              if (!opened && context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Could not open link')),
                                                );
                                              }
                                            }
                                          : null,
                                      child: Text(
                                        message.text,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isMe ? Colors.white : Colors.black,
                                          decoration: message.text.startsWith('http')
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: message.isRead ? const Color(0xFF25D366) : Colors.white60,
                                      ),
                                    ],
                                  ],
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

              // 🎹 PILL-SHAPED INSTAGRAM FOOTER BAR
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!, width: 1), // Thin border container
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 22),
                              onPressed: _pickImage,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Message...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: const Text(
                        'Send',
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ⏳ LOADING OVERLAY for Image Uploads
          ListenableBuilder(
            listenable: _chatNotifier,
            builder: (context, _) {
              if (_chatNotifier.isLoading) {
                return Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

}