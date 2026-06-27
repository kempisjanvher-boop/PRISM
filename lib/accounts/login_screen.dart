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
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        String uniqueUserCode = "Guest";
        String uniqueUserSubCode = "000000";
        String userRole = "User";

        final userId = userCredential.user!.uid;

        // Try to fetch user profile rules from Firestore
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data() as Map<String, dynamic>;

            userRole = data['role'] ?? userRole;

            // Extract code configurations if they exist in the document data
            uniqueUserCode = data['userCode'] ?? "";
            uniqueUserSubCode = data['userSubCode'] ?? "";
          }
        } catch (firestoreError) {
          debugPrint("FIRESTORE ACCESS ERROR: $firestoreError");
          throw Exception(
            "Database Access Denied. Verify your Firestore Rules configuration.",
          );
        }

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint("Failed to update lastLogin: $e");
        }

        bool hasBadCode = uniqueUserCode.startsWith("67") || uniqueUserCode.isEmpty || uniqueUserCode == "Guest";
        bool hasBadSubCode = uniqueUserSubCode == "000000" || uniqueUserSubCode.isEmpty;

        if (hasBadCode || hasBadSubCode) {
          int uniqueHashSeed = userId.hashCode.abs();
          int dynamicId = 100000 + (uniqueHashSeed % 900000); // 6-digit dynamic number

          if (hasBadCode) uniqueUserCode = dynamicId.toString();

          if (hasBadSubCode) {
            uniqueUserSubCode = (userRole == "Administrator" || userRole == "Admin")
                ? "ADM-$uniqueUserCode"
                : "USR-$uniqueUserCode";
          }

          // Automatically clean up and save the new format back to Firestore
          try {
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'userCode': uniqueUserCode,
              'userSubCode': uniqueUserSubCode,
            });
          } catch (e) {
            debugPrint("Failed to auto-clean user data in database: $e");
          }
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (uniqueUserCode.isEmpty || uniqueUserCode == "Guest" || uniqueUserCode == "000000") {
          int uniqueHashSeed = userId.hashCode.abs();

          // Generates a clean, random-looking but permanent 6-digit number between 100000 and 999999
          int dynamicId = 100000 + (uniqueHashSeed % 900000);

          uniqueUserCode = dynamicId.toString();
        }

        if (uniqueUserSubCode.isEmpty || uniqueUserSubCode == "000000") {
          if (userRole == "Administrator" || userRole == "Admin") {
            uniqueUserSubCode = "ADM-$uniqueUserCode";
          } else {
            uniqueUserSubCode = "USR-$uniqueUserCode";
          }
        }

        // 2. Perform the routing
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
              builder: (context) => PrismDashboard(
                userCode: uniqueUserCode,
                userSubCode: uniqueUserSubCode,
              ),
            ),
          );
        }
      }
    } catch (e) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Sign In Failure"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: brandBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/onboarding.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Responsive Top Banner Line
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 12,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [brandBlue, brandGold],
                ),
              ),
            ),
          ),

          // Back Navigation Arrow - Optimized for tablet touch interactions
          Positioned(
            top: 30,
            left: isLandscape ? 32 : 16,
            child: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Centralized Form Box Viewport Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 48.0 : 24.0,
                    vertical: 16.0
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isLandscape ? 10 : 30),
                      Image.asset(
                        'asset/MLA.png',
                        height: isLandscape ? 130 : 180,
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
                              style: TextStyle(color: Color(0xFF0F1B54), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Login Card Framework Container
                      Container(
                        width: 460,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
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
                              child: Image.asset('asset/login-prism.png', height: 48, fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Inventory System",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: brandBlue),
                            ),
                            const Text(
                              "Sign in to your account",
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                            const SizedBox(height: 28),

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
                            const SizedBox(height: 18),
                            _buildTextField(
                              label: "Password",
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 22),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Password field is required";
                                if (value.length < 6) return "Password must be at least 6 characters long";
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: brandBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                                    : const Text(
                                  "Sign In",
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            isDense: true,
            suffixIcon: suffixIcon,
            errorStyle: const TextStyle(height: 0.9, fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: brandBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}