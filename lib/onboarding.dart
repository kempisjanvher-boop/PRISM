import 'package:flutter/material.dart';
import 'main_dashboard.dart';
import 'scan_handler.dart';
import './accounts/login_screen.dart';

class PrismOnboardingScreen extends StatelessWidget {
  const PrismOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetching device orientation to dynamically handle edge padding targets
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fullscreen Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/onboarding.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Background Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

          // 2. Foreground Layout Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 64.0 : 40.0,
                      vertical: 24.0
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isLandscape ? 10 : 30),

                        // Branding Header Block
                        Image.asset(
                          'asset/MLA.png',
                          height: isLandscape ? 160 : 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            text: "Hello, Welcome to ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                            ),
                            children: [
                              TextSpan(
                                text: "MLA.Digital",
                                style: TextStyle(
                                  color: Color(0xFF0F1B54),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isLandscape ? 40 : 60),

                        // Prompt Title
                        const Text(
                          "What do you want today?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // 3. Selection Action Cards (Protected Router)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 850;
                            return Flex(
                              direction: isWide ? Axis.horizontal : Axis.vertical,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // PUBLIC ROAD: View access is unlocked immediately
                                _buildActionCard(
                                  context: context,
                                  title: "VIEW",
                                  highlightedWord: "Inventory",
                                  subtitle: "Track stock and shipped packages",
                                  imgIcon: Image.asset(
                                    'asset/view.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                  iconColor: Colors.grey.shade700,
                                  isProtected: false,
                                  targetScreen: const PrismMainDashboard(),
                                ),

                                SizedBox(width: isWide ? 32 : 0, height: isWide ? 0 : 24),

                                // PROTECTED ROAD: Prompts sign-in before changing state data
                                _buildActionCard(
                                  context: context,
                                  title: "EDIT",
                                  highlightedWord: "Inventory",
                                  subtitle: "Manage stock and shipped packages",
                                  imgIcon: Image.asset(
                                    'asset/edit.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                  iconColor: Colors.grey.shade700,
                                  isProtected: true,
                                  targetScreen: const ScanHandlerScreen(),
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: isLandscape ? 50 : 70),

                        // 4. Interactive Action Entry Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F1B54).withValues(alpha: 0.9),
                            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            side: const BorderSide(color: Colors.white24),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action Selection Card Builder with Route Protection Logic
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String highlightedWord,
    required String subtitle,
    required Image imgIcon,
    required Color iconColor,
    required Widget targetScreen,
    required bool isProtected,
  }) {
    return GestureDetector(
      onTap: () {
        if (isProtected) {
          // Inform user they must log in to change database values
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Authentication Required: Please sign in to edit assets."),
                ],
              ),
              backgroundColor: Color(0xFF0F1B54),
              duration: Duration(seconds: 3),
            ),
          );

          // Re-route the user to the Login screen directly
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          // Public navigation allowed safely
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        }
      },
      child: Container(
        width: 380,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: isProtected
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // If the card is protected, place a small padlock indicator in the upper right
            if (isProtected)
              Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: imgIcon,
                ),
                const SizedBox(height: 20),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "$title ",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      TextSpan(
                        text: highlightedWord,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}