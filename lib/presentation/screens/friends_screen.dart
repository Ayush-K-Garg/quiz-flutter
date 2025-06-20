import 'package:flutter/material.dart';
import 'package:quiz/core/services/friend_service.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';


class FriendScreen extends StatelessWidget {
  final String friendUserId = "some_user_id_here"; // The user to send request to

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(title: Text('Friends')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await sendFriendRequest(friendUserId);
          },
          child: Text('Send Friend Request'),
        ),
      ),
    );
  }
}
