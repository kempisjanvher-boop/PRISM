import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../inventory/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  static const Color brandBlue = Color(0xFF0C245E);
  static const Color brandGold = Color(0xFF8F6D51);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Update this method directly inside your login_screen.dart file
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );


      if (userCredential.user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        String uniqueUserCode = "Guest";
        String uniqueUserSubCode = "000000";

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          uniqueUserCode = data['userCode'] ?? uniqueUserCode;
          uniqueUserSubCode = data['userSubCode'] ?? uniqueUserSubCode;
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Route into the live synced dashboard profile setup cleanly
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PrismMainDashboard(
              userCode: uniqueUserCode,
              userSubCode: uniqueUserSubCode,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      // Catch handling errors transparently and display alert notifications
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Sign In Failure"),
          content: Text(e.message ?? "An unexpected authentication error occurred."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: brandBlue)),
            ),
          ],
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Cargo Ship Image Backdrop
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/onboarding.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Top Decorative Bar (Precise Brand Gradient match)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 25,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [brandBlue, brandGold],
                ),
              ),
            ),
          ),

          // Navigation Back Arrow (Top Left)
          Positioned(
            top: 45, left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Foreground Form Container Layout Sequence
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey, // Form validation framework hook binding execution context
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      Image.asset(
                        'asset/MLA.png',
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),

                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          text: "Hello, Welcome to ",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                          children: [
                            TextSpan(
                              text: "MLA.Digital",
                              style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Centralized Interactive Login Card Matrix
                      Container(
                        width: 480,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Brand System Icon Image Container
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset('asset/login-prism.png'),
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              "Inventory System",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: brandBlue),
                            ),
                            const Text(
                              "Sign in to your account",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 32),

                            // Dynamic Forms Content Pipeline Inputs
                            _buildTextField(
                              label: "Email Address",
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email field is required";
                                }

                                // Updated robust regex: allows letters, numbers, dots, hyphens, and any length of TLD (like .digital)
                                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                                if (!emailRegex.hasMatch(value.trim())) {
                                  return "Enter a valid email address context";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              label: "Password",
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Password field is required";
                                if (value.length < 6) return "Password must be at least 6 characters long";
                                return null;
                              },
                            ),
                            const SizedBox(height: 36),

                            // Dynamic Action Action Trigger Button Form Element
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin, // Locks tracking loops while authenticating
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 24, width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                                    : const Text(
                                  "Sign In",
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Consistent Input Field Template styled to match design spec references
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              isDense: true,
              suffixIcon: suffixIcon,
              errorStyle: const TextStyle(height: 0.8, fontSize: 12), // Keeps errors nicely aligned below text boxes
            ),
          ),
        ),
      ],
    );
  }
}