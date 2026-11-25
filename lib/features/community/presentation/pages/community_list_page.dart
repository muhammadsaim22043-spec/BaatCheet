// lib/features/community/presentation/pages/community_list_page.dart

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/community_notifier.dart';
import 'community_room_page.dart';
import 'create_community_page.dart';
import 'search_community_page.dart';

class CommunityListPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const CommunityListPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage> {
  final CommunityNotifier _notifier = sl<CommunityNotifier>();

  @override
  void initState() {
    super.initState();
    _notifier.listenToUserCommunities(widget.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _notifier,
      builder: (context, _) {
        if (_notifier.isLoading && _notifier.userCommunities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: Column(
            children: [
              // Top Action Bar for Search & Create
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchCommunityPage(
                                currentUserId: widget.currentUserId,
                                currentUserName: widget.currentUserName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.search, size: 20),
                        label: const Text('Search Public Communities'),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateCommunityPage(
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add),
                      tooltip: 'New Community',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Communities List
              Expanded(
                child: _notifier.userCommunities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 72, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No Communities Yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Search for public communities or create a new group!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _notifier.userCommunities.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final community = _notifier.userCommunities[index];
                          final isAdmin = community.adminId == widget.currentUserId;

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: community.isPublic ? Colors.blue[100] : Colors.amber[100],
                              child: Icon(
                                community.isPublic ? Icons.public : Icons.lock,
                                color: community.isPublic ? Colors.blue[800] : Colors.amber[800],
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    community.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              community.lastMessage ?? community.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              '${community.memberIds.length} 👤',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommunityRoomPage(
                                    community: community,
                                    currentUserId: widget.currentUserId,
                                    currentUserName: widget.currentUserName,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateCommunityPage(
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Group'),
          ),
        );
      },
    );
  }
}
