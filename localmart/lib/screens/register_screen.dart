import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localmart/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  String _errorText = "";
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void register() async {
    try {
      await authService.value.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
      );
      setState(() {
        _errorText = "";
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = e.message ?? "Unexpected error!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up!")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(8.0),
          child: Column(
            children: [
              Text("Email"),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(errorText: _errorText),
              ),
              Text("Username"),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(errorText: _errorText),
              ),
              Text("Password"),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(errorText: _errorText),
              ),
              TextButton(
                onPressed: () {
                  register();
                },
                child: Text("Sign Up"),
              ),
              TextButton(
                onPressed: () {
                  authService.value.signInWithGoogle();
                },
                child: Text("Or Login With"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}