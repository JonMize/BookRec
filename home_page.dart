import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_review_page.dart';
import 'recent_reviews_page.dart';
import 'your_reviews_page.dart';
import 'recommendations_page.dart';

class HomePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void handleLogout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddReviewPage()),
                );
              },
              child: Text('Add a Review'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecommendationsPage()),
                );
              },
              child: const Text("Get Recommendations"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const YourReviewsPage()),
                );
              },
              child: const Text("Your Reviews"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecentReviewsPage()),
                );
              },
              child: const Text("Recent Reviews"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => handleLogout(context),
          child: Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        ),
      ),
    );
  }
}
