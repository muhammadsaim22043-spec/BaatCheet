// lib/features/community/presentation/pages/search_community_page.dart

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/community_notifier.dart';
import 'community_room_page.dart';

class SearchCommunityPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const SearchCommunityPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<SearchCommunityPage> createState() => _SearchCommunityPageState();
}

class _SearchCommunityPageState extends State<SearchCommunityPage> {
  final CommunityNotifier _notifier = sl<CommunityNotifier>();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _notifier.searchPublicCommunities(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search public communities by name...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _notifier.searchPublicCommunities('');
              },
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _notifier,
        builder: (context, _) {
          if (_notifier.isSearching) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_searchController.text.trim().isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Type a name to search public communities', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          if (_notifier.searchResults.isEmpty) {
            return Center(
              child: Text(
                'No public communities found matching "${_searchController.text}".',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return ListView.separated(
            itemCount: _notifier.searchResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final community = _notifier.searchResults[index];
              final isMember = community.memberIds.contains(widget.currentUserId);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.public, color: Colors.blue),
                ),
                title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(community.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: isMember
                    ? OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
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
                        child: const Text('Open'),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          final success = await _notifier.joinCommunity(
                            communityId: community.id,
                            userId: widget.currentUserId,
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Joined ${community.name}!')),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommunityRoomPage(
                                  community: community,
                                  currentUserId: widget.currentUserId,
                                  currentUserName: widget.currentUserName,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Join'),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
