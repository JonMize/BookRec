import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddReviewPage extends StatefulWidget {
  @override
  _AddReviewPageState createState() => _AddReviewPageState();
}

class _AddReviewPageState extends State<AddReviewPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _books = [];
  bool _isLoading = false;

  Future<void> searchBooks(String query) async {
    const String apiKey = '';
    const String baseUrl = 'https://www.googleapis.com/books/v1/volumes';

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('$baseUrl?q=$query&key=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _books = data['items'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error fetching books: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void openReviewDialog(String bookTitle, String authorName) {
    final TextEditingController _reviewController = TextEditingController();
    bool isLiked = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review: $bookTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(labelText: 'Your Review'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => isLiked = true),
                  icon: Icon(Icons.thumb_up, color: Colors.green),
                  label: Text('Like'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => isLiked = false),
                  icon: Icon(Icons.thumb_down, color: Colors.red),
                  label: Text('Dislike'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await saveReview(bookTitle, authorName,
                  _reviewController.text.trim(), isLiked);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> saveReview(
      String bookTitle, String authorName, String review, bool isLiked) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Fetch the username from the 'users' collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final username = userDoc.data()?['username'] ?? 'Unknown User';

      await FirebaseFirestore.instance.collection('reviews').add({
        'uid': currentUser.uid,
        'username': username,
        'bookTitle': bookTitle,
        'authorName': authorName,
        'review': review,
        'isLiked': isLiked,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add a Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a Book',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      searchBooks(query);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        final title = book['volumeInfo']['title'] ?? 'No Title';
                        final authors =
                            book['volumeInfo']['authors']?.join(', ') ??
                                'No Author';
                        return ListTile(
                          title: Text(title),
                          subtitle: Text(authors),
                          onTap: () => openReviewDialog(title, authors),
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
