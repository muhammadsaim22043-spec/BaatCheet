// lib/features/auth/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';

class ProfilePage extends StatelessWidget {
  final UserEntity user;
  final bool isCurrentUser;

  const ProfilePage({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkAppBar = Theme.of(context).primaryColor.computeLuminance() < 0.5;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default left button
        title: Text(isCurrentUser ? 'My Profile' : 'Contact Info'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: isDarkAppBar ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward), // Right-side back button
            onPressed: () => Navigator.pop(context),
            color: isDarkAppBar ? Colors.white : Colors.black,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user.displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user.phoneNumber,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(user.email.isNotEmpty ? user.email : 'Not provided'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone Number'),
              subtitle: Text(user.phoneNumber),
            ),
            if (isCurrentUser) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Privacy settings and other options can be added here in the future.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
