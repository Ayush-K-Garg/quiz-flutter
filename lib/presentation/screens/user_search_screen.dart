import 'package:flutter/material.dart';
import 'package:quiz/core/services/user_api.dart';

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

  void search() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      loading = true;
    });

    try {
      final result = await userApi.searchUsers(query);
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
    loadSuggestedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Search & Suggestions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                labelText: 'Search users by name or email',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: search,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: user['picture'] != null
                          ? CircleAvatar(
                        backgroundImage: NetworkImage(user['picture']),
                      )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user['name'] ?? 'No Name'),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () {
                        // You can add sending friend request here
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
