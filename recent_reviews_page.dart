import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecentReviewsPage extends StatelessWidget {
  const RecentReviewsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Reviews"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('timestamp', descending: true) // Order by most recent
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reviews found"));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
              final bookTitle = review['bookTitle'] ?? 'Unknown Title';
              final authorName = review['authorName'] ?? 'Unknown Author';
              final username = review['username'] ?? 'Anonymous';
              final reviewText = review['review'] ?? '';
              final isLiked = review['isLiked'] ?? false;
              final timestamp = review['timestamp'] != null
                  ? (review['timestamp'] as Timestamp).toDate()
                  : DateTime.now();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$bookTitle by $authorName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Reviewed by: $username"),
                      const SizedBox(height: 8),
                      Text(
                        reviewText,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_down,
                            color: isLiked ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${timestamp.toLocal()}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
