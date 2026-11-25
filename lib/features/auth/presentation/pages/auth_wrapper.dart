// lib/features/auth/presentation/pages/auth_wrapper.dart

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/auth_notifier.dart';
import 'profile_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart'; // Ensure this is imported
import 'login_page.dart';
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthNotifier _authNotifier = sl<AuthNotifier>();

  @override
  void initState() {
    super.initState();
    // Check if a user is already cached when the app boots up
    _authNotifier.checkExistingSession();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 THE CRITICAL FIX: Wrap the screen inside a ListenableBuilder
    // This tells the UI to rebuild the entire routing branch the exact millisecond notifyListeners() is called.
    return ListenableBuilder(
      listenable: _authNotifier,
      builder: (context, child) {
        final state = _authNotifier.state;

        // 🎉 Success State -> Show Direct Messages Dashboard
        if (state is AuthSuccess) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Messages'),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          user: state.user,
                          isCurrentUser: true,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _authNotifier.logout(),
                ),
              ],
            ),
            body: ChatListPage(currentUserId: state.user.id),
          );
        }

        // 🔐 Every other state (Initial, Loading, OTP sent, Error) is rendered by
        // LoginPage itself. Keeping it in the tree preserves the typed phone number
        // and the Login/Register toggle across state changes.
        return const LoginPage();
      },
    );
  }
}