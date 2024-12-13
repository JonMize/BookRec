import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({Key? key}) : super(key: key);

  @override
  _RecommendationsPageState createState() => _RecommendationsPageState();
}

List<Map<String, String>> _parseRecommendations(String text) {
  List<Map<String, String>> recommendations = [];
  final entries = text.split(RegExp(r'\d+\.\s'));

  for (var entry in entries) {
    if (entry.trim().isEmpty) continue;

    final titleMatch = RegExp(r'Title:\s*(.*)').firstMatch(entry);
    final authorMatch = RegExp(r'Author:\s*(.*)').firstMatch(entry);
    final descriptionMatch = RegExp(r'Description:\s*(.*)').firstMatch(entry);

    if (titleMatch != null && authorMatch != null && descriptionMatch != null) {
      recommendations.add({
        'title': titleMatch.group(1)?.trim() ?? 'Unknown Title',
        'author': authorMatch.group(1)?.trim() ?? 'Unknown Author',
        'description':
            descriptionMatch.group(1)?.trim() ?? 'No description available',
      });
    }
  }

  return recommendations;
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  List<Map<String, String>> recommendedBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getRecommendations();
  }

  Future<void> _getRecommendations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Fetch the reviews written by the logged-in user where isLiked == true
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('uid', isEqualTo: currentUser.uid)
          .where('isLiked', isEqualTo: true)
          .get();

      // Prepare data for OpenAI API (bookTitle, authorName)
      List<String> likedBooks = [];
      for (var reviewDoc in reviewsSnapshot.docs) {
        final data = reviewDoc.data();
        final bookTitle = data['bookTitle'];
        final authorName = data['authorName'];
        likedBooks.add('Title: $bookTitle, Author: $authorName');
      }

      // Send to OpenAI API to get recommendations
      if (likedBooks.isNotEmpty) {
        final recommendations =
            await _fetchRecommendationsFromOpenAI(likedBooks);
        setState(() {
          recommendedBooks = recommendations;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching reviews or recommendations: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> _fetchRecommendationsFromOpenAI(
      List<String> likedBooks) async {
    final openAiKey = '';
    final prompt = '''
The user has liked the following books:

${likedBooks.join("\n")}

Based on these preferences, recommend 5 books that the user might enjoy. For each recommendation, include:
- Title
- Author
- Description of the book (one or two sentences)

Provide the response in this format:
1. Title: <Book Title>
   Author: <Author Name>
   Description: <Short Description>
2. Title: <Book Title>
   Author: <Author Name>
   Description: <Short Description>
''';

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo', // Updated model
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'].toString().trim();
      return _parseRecommendations(text);
    } else {
      print('Failed OpenAI Response: ${response.statusCode}');
      print('Response Body: ${response.body}');
      throw Exception('Failed to fetch recommendations from OpenAI');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Recommendations')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendedBooks.isEmpty
              ? const Center(child: Text('No recommendations available.'))
              : ListView.builder(
                  itemCount: recommendedBooks.length,
                  itemBuilder: (context, index) {
                    final book = recommendedBooks[index];
                    return ListTile(
                      title: Text(book['title'] ?? 'Unknown Title'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Author: ${book['author']}'),
                          const SizedBox(height: 4),
                          Text('Description: ${book['description']}'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
