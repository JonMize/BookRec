import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'pigeon_user_details.dart';

// Assuming PigeonUserDetails is generated or available
// Update with actual import path

class SignupSigninPage extends StatefulWidget {
  @override
  _SignupSigninPageState createState() => _SignupSigninPageState();
}

class _SignupSigninPageState extends State<SignupSigninPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  void toggleForm() {
    setState(() {
      isSignIn = !isSignIn;
    });
  }

  Future<void> handleSignInOrSignUp() async {
    try {
      if (isSignIn) {
        // Login
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Fetch user details
        PigeonUserDetails userDetails =
            await PigeonUserDetails.fetchFromAuth(userCredential.user!);
        print(
            "Logged in as: ${userDetails.email}, Username: ${userDetails.username}");
      } else {
        // Sign up
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user details to Firestore
        await PigeonUserDetails.saveToFirestore(
          userCredential.user!,
          _usernameController.text.trim(),
        );

        print("User signed up: ${_emailController.text.trim()}");
      }

      // Navigate to Home Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      print("Error during sign-in/sign-up: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isSignIn ? 'Sign In' : 'Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (!isSignIn)
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleSignInOrSignUp,
              child: Text(isSignIn ? 'Sign In' : 'Sign Up'),
            ),
            TextButton(
              onPressed: toggleForm,
              child: Text(isSignIn
                  ? 'Create an Account'
                  : 'Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
