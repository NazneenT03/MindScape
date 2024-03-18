import 'package:flutter/material.dart';
import 'package:mindscape/pages/signup_page.dart';
import 'package:mindscape/reusable_widgets/reusable_widgets.dart';
import 'package:mindscape/utilities/colors_util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("ffe6e8"),
              hexStringToColor("acd8aa"),
              hexStringToColor("f48498")
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).size.height * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                logoWidget(
                    "assests/images/mindscape-high-resolution-logo-transparent.png"),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Username: ", Icons.person_outline,
                    false, _emailTextController),
                const SizedBox(
                  height: 20,
                ),
                reusableTextField("Enter Password: ", Icons.lock_outline, true,
                    _passwordTextController),
                const SizedBox(
                  height: 20,
                ),
                logInSignUpButton(context, true, () {}),
                signUpOption(context)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Row signUpOption(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Don't have an account? Try to",
          style: TextStyle(color: Colors.white70)),
      GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SignUpPage()));
        },
        child: const Text(
          " Sign Up",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
    ],
  );
}
