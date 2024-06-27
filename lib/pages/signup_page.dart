import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mindscape/pages/login_page.dart';
import 'package:mindscape/reusable_widgets/reusable_widgets.dart';
import 'package:mindscape/utilities/colors_util.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();

  Future<void> registerUser(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://192.168.1.2:8000/register/'), // Replace with your Django backend URL
        headers: {
          'Content-Type': 'application/json', // Specify the content-type
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Registration successful
        print('User registered successfully');
        // Navigate to login page after successful registration
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // Registration failed
        print('Failed to register user: ${response.body}');
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register user. Please try again.')),
        );
      }
    } catch (e) {
      print('Error registering user: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Color(0xf48498),
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 172, 216, 170),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  hexStringToColor("ffe6e8"),
                  hexStringToColor("acd8aa"),
                  hexStringToColor("f48498"),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.2),
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assests/images/mindscape-high-resolution-logo-transparent.png',
                width: 50,
                height: 50,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Username",
                    Icons.person_outline,
                    false,
                    _userNameTextController,
                  ),
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Email ID",
                    Icons.person_outline,
                    false,
                    _emailTextController,
                  ),
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Password",
                    Icons.lock_outlined,
                    true,
                    _passwordTextController,
                  ),
                  const SizedBox(height: 20),
                  logInSignUpButton(context, false, () {
                    // Call registerUser function when Sign Up button is pressed
                    registerUser(
                      _userNameTextController.text.trim(),
                      _emailTextController.text.trim(),
                      _passwordTextController.text.trim(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
