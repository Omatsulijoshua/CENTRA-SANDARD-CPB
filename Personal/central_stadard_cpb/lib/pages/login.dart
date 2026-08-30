import 'package:central_stadard_cpb/pages/main_page.dart';
import 'package:central_stadard_cpb/pages/child_dashboard.dart';
import 'package:central_stadard_cpb/pages/signup.dart';
import 'package:central_stadard_cpb/services/api_service.dart';
import 'package:central_stadard_cpb/services/auth_service.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  bool loading = false;
  bool childMode = false;

  userLogin() async {
    setState(() => loading = true);
    try {
      if (childMode) {
        final response = await ApiService.childLogin(emailcontroller.text.trim(), passwordcontroller.text.trim());
        if (response['statusCode'] == 200) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChildDashboard(childData: Map<String, dynamic>.from(response['data']))),
          );
          return;
        }
        throw Exception("Invalid child username or PIN");
      }

      final authService = AuthService();
      final user = await authService.loginUser(
        email: emailcontroller.text.trim(),
        password: passwordcontroller.text.trim(),
      );

      if (user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Login Successful",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Invalid email or password",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Error: $e"),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
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
                padding: const EdgeInsets.only(top: 80.0, bottom: 40),
                child: Image.asset(
                  "assets/logo.png",
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF054C53)),
                  ),
                  Text(
                    childMode ? "Child sign in" : "Sign in to continue to your account",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        _modeButton("Normal", !childMode, () => setState(() => childMode = false)),
                        _modeButton("Child", childMode, () => setState(() => childMode = true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(emailcontroller, childMode ? "Child username" : "Email", childMode ? Icons.child_care : Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildTextField(passwordcontroller, childMode ? "PIN" : "Password", Icons.lock_outline, isPassword: true),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text("Forgot Password?", style: TextStyle(color: Color(0xFF0A6E79), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: loading ? null : userLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A6E79),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: loading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Sign In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUp())),
                        child: const Text("Sign up", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
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

  Widget _modeButton(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0A6E79) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
