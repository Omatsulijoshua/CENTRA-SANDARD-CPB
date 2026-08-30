import 'package:central_stadard_cpb/pages/main_page.dart';
import 'package:central_stadard_cpb/pages/login.dart';
import 'package:central_stadard_cpb/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> registration() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Please fill all details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Account Created 🎉", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Registration failed. Email might be in use.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0, bottom: 20),
                child: Image.asset("assets/logo.png", width: 180, height: 180, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF054C53))),
                  const Text("Join Central Standard CPB today", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 30),
                  _buildTextField(nameController, "Full Name", Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildTextField(emailController, "Email Address", Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildTextField(passwordController, "Password", Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : registration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A6E79),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Login())),
                        child: const Text("Sign in", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF0A6E79)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
