import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

// Helper to get Firebase ID token
Future<String?> getFirebaseIdToken() async {
  final user = FirebaseAuth.instance.currentUser;
  return user != null ? await user.getIdToken() : null;
}

Future<void> sendFriendRequest(String recipientId) async {
  final idToken = await getFirebaseIdToken();

  final response = await http.post(
    Uri.parse('https://quiz-backend-lnrb.onrender.com/api/friends/request'),
   headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'recipient': recipientId,
    }),
  );

  if (response.statusCode == 201) {
    print('Friend request sent');
  } else {
    print('Failed: ${response.body}');
  }
}
