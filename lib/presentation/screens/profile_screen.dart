import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart'; // ✅ Make sure GoRouter is imported

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E3F),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(
        child: Text(
          "⚠️ Not logged in",
          style: TextStyle(color: Colors.white70),
        ),
      )
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                user.displayName ?? "No Name",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user.email ?? "No Email",
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;

                  // ✅ GoRouter safe logout
                  context.go('/login');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("🔒 Logged out")),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
