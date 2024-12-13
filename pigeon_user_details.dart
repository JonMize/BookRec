import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PigeonUserDetails {
  final String email;
  final String username;

  PigeonUserDetails({
    required this.email,
    required this.username,
  });

  // Factory constructor to create a PigeonUserDetails instance from Firestore data
  factory PigeonUserDetails.fromFirestore(Map<String, dynamic> data) {
    print("Parsing data into PigeonUserDetails: $data");

    if (!data.containsKey('email') || !data.containsKey('username')) {
      throw Exception('Missing required fields in Firestore data');
    }

    return PigeonUserDetails(
      email: data['email'] ?? 'Unknown Email',
      username: data['username'] ?? 'Unknown Username',
    );
  }

  // Fetch user details from Firestore using FirebaseAuth's User object
  static Future<PigeonUserDetails> fetchFromAuth(User user) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      // Log the fetched document and its type
      print("Fetched Firestore document: ${userDoc.data()}");
      print("Document data type: ${userDoc.data()?.runtimeType}");

      if (!userDoc.exists) {
        throw Exception('User document does not exist for UID: ${user.uid}');
      }

      final data = userDoc.data();
      if (data == null) {
        throw Exception(
            'Unexpected Firestore data format: ${data.runtimeType}');
      }

      return PigeonUserDetails.fromFirestore(data);
    } catch (e) {
      print("Error in fetchFromAuth: $e");
      throw Exception('Failed to fetch user details: $e');
    }
  }

  // Save user details to Firestore
  static Future<void> saveToFirestore(User user, String username) async {
    try {
      final userData = {
        'email': user.email,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData);

      print("User details successfully saved to Firestore: $userData");
    } catch (e) {
      print("Error saving user details to Firestore: $e");
      throw Exception('Failed to save user details: $e');
    }
  }
}
