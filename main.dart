import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup_signin_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookRecs',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          SignupSigninPage(), // Set the starting page to the signup/sign-in page
    );
  }
}
