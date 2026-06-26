import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../inventory/dashboard.dart';
import '../admin/dashboard_admin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Authenticate with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        String uniqueUserCode = "Guest";
        String uniqueUserSubCode = "000000";
        String userRole = "User"; // Default fallback role

        // 2. Fetch profile from Firestore with hardened exception catching
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data() as Map<String, dynamic>;
            uniqueUserCode = data['userCode'] ?? uniqueUserCode;
            uniqueUserSubCode = data['userSubCode'] ?? uniqueUserSubCode;
            userRole = data['role'] ?? userRole;
          }
        } catch (firestoreError) {
          debugPrint("FIRESTORE ACCESS ERROR: $firestoreError");
          // Rethrow to general handler or parse error directly here
          throw Exception("Database Access Denied. Verify your Firestore Rules configuration.");
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        // ==========================================
        // DYNAMIC ROLE-BASED WORKSPACE ROUTING
        // ==========================================
        if (userRole == "Administrator" || userRole == "Admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PrismAdminDashboard(
                userCode: uniqueUserCode,
                userSubCode: uniqueUserSubCode,
              ),
            ),
          );
        } else {
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
      }
    } catch (e) {
      // Catch both Auth issues and unexpected database permission blocks gracefully
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String errorMessage = "An unexpected authentication error occurred.";
      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? errorMessage;
      } else if (e is FirebaseException) {
        errorMessage = e.message ?? "Database rule blocking: ${e.toString()}";
      } else {
        errorMessage = e.toString().replaceAll("Exception: ", "");
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Sign In Failure"),
          content: Text(errorMessage),
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/onboarding.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
          Positioned(
            top: 45, left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
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
                      Container(
                        width: 480,
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
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
                            _buildTextField(
                              label: "Email Address",
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email field is required";
                                }
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
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
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
              errorStyle: const TextStyle(height: 0.8, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}