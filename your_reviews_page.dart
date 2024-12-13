import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class YourReviewsPage extends StatelessWidget {
  const YourReviewsPage({Key? key}) : super(key: key);

  Future<String?> _fetchUsername() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    return userDoc.data()?['username'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Reviews"),
      ),
      body: FutureBuilder<String?>(
        future: _fetchUsername(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Error fetching username."));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('uid',
                    isEqualTo:
                        FirebaseAuth.instance.currentUser!.uid) // Match uid
                .orderBy('timestamp', descending: true) // Order by most recent
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print("Error fetching reviews: ${snapshot.error}");
                return const Center(child: Text("Error loading reviews."));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print(
                    "No reviews found for uid: ${FirebaseAuth.instance.currentUser!.uid}");
                return const Center(child: Text("No reviews found."));
              }

              final reviews = snapshot.data!.docs;

              print(
                  "Found ${reviews.length} reviews for uid: ${FirebaseAuth.instance.currentUser!.uid}");

              return ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final data = review.data() as Map<String, dynamic>;
                  final bookTitle = data['bookTitle'] ?? 'Unknown Title';
                  final authorName = data['authorName'] ?? 'Unknown Author';
                  final reviewText = data['review'] ?? '';
                  final isLiked = data['isLiked'] ?? false;
                  final username = data['username'] ?? 'Anonymous';
                  final timestamp = data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp).toDate()
                      : DateTime.now();

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text("$bookTitle by $authorName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("Reviewed by: $username"),
                          Text("Review: $reviewText"),
                          Row(
                            children: [
                              Icon(
                                isLiked ? Icons.thumb_up : Icons.thumb_down,
                                color: isLiked ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Last updated: ${timestamp.toLocal()}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editReview(
                          context,
                          review.id,
                          reviewText,
                          isLiked,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _editReview(BuildContext context, String reviewId, String currentReview,
      bool currentLikeStatus) {
    final _reviewController = TextEditingController(text: currentReview);
    bool isLiked = currentLikeStatus;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Review"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(labelText: "Review"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      isLiked = true;
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.thumb_up, color: Colors.green),
                        SizedBox(width: 4),
                        Text("Like"),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      isLiked = false;
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.thumb_down, color: Colors.red),
                        SizedBox(width: 4),
                        Text("Dislike"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final updatedReview = _reviewController.text.trim();
                if (updatedReview.isEmpty) return;

                try {
                  await FirebaseFirestore.instance
                      .collection('reviews')
                      .doc(reviewId)
                      .update({
                    'review': updatedReview,
                    'isLiked': isLiked,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Review updated successfully!")),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating review: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
