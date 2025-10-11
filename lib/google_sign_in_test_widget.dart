// This is a testing widget for Google Sign-In.
// It is not currently used in the app, but could be
// reused for testing or a future user settings page.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bible/services/auth_manager.dart';

class GoogleSignInTestWidget extends StatefulWidget {
  const GoogleSignInTestWidget({super.key});

  @override
  State<GoogleSignInTestWidget> createState() => _GoogleSignInTestWidgetState();
}

class _GoogleSignInTestWidgetState extends State<GoogleSignInTestWidget> {
  final _authManager = AuthManager();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authManager.userChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          // 🔹 Not signed in
          return Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                await _authManager.signInWithGoogle();
              },
            ),
          );
        }

        // 🔹 Signed in
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.photoURL != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user.photoURL!),
                ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? 'No display name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(user.email ?? 'No email'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                onPressed: () async {
                  await _authManager.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
