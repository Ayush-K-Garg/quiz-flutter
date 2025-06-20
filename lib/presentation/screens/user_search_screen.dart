import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quiz/core/services/user_api.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';


class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final UserApi userApi = UserApi();
  final TextEditingController searchController = TextEditingController();
  List<dynamic> users = [];
  bool loading = false;

  Timer? debounceTimer;

  void search(String query) async {
    if (query.trim().isEmpty) {
      loadSuggestedUsers(); // fallback to suggestions if field is cleared
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await userApi.searchUsers(query.trim());
      setState(() {
        users = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }

    setState(() {
      loading = false;
    });
  }

  void onSearchChanged(String query) {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 400), () {
      search(query);
    });
  }

  void loadSuggestedUsers() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await userApi.getSuggestedUsers();
      setState(() {
        users = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading suggested users: $e')),
      );
    }

    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });
    loadSuggestedUsers();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(title: const Text('User Search & Suggestions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search users by name or email',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    loadSuggestedUsers();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text('No users found.'))
                    : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: user['picture'] != null
                          ? CircleAvatar(
                        backgroundImage:
                        NetworkImage(user['picture']),
                      )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user['name'] ?? 'No Name'),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () {
                        // Optionally trigger friend request
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
