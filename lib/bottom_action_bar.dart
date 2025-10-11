import 'package:flutter/material.dart';
import 'package:bible/services/auth_manager.dart';

class BottomActionBar extends StatefulWidget {
  const BottomActionBar({super.key});

  @override
  State<BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<BottomActionBar> {
  final AuthManager _auth = AuthManager();

  @override
  void initState() {
    super.initState();
    _auth.userChanges.listen((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              if (user == null) {
                try {
                  await _auth.signInWithGoogle();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Sign-in failed.')));
                  }
                  print(e);
                }
              } else {
                await _auth.signOut();
              }
              setState(() {});
            },
            child: CircleAvatar(
              radius: 24,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
