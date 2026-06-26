import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'scan_handler.dart';
import './accounts/login_screen.dart';

class PrismOnboardingScreen extends StatelessWidget {
  const PrismOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0), // Expanded layout padding for high-res canvases
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Branding Header Block (Properly scaled for high-density 2048x2732 px)
                      Image.asset(
                        'asset/MLA.png',
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
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

                      const SizedBox(height: 80), // Increased separation gap

                      // Prompt Text
                      const Text(
                        "What do you want today?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42, // Crisp upscale matching display scale proportions
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // 3. Selection Action Cards (Responsive Layout with revised breakpoints)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Breakpoint optimized for tablet/desktop widths on large asset spaces
                          bool isWide = constraints.maxWidth > 800;
                          return Flex(
                            direction: isWide ? Axis.horizontal : Axis.vertical,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionCard(
                                context: context,
                                title: "VIEW",
                                highlightedWord: "Inventory",
                                subtitle: "Track stock or shipped packages",
                                imgIcon: Image.asset(
                                  'asset/view.png',
                                  width: 110,  // Upscaled illustration target
                                  height: 110,
                                ),
                                iconColor: Colors.grey.shade700,
                                targetScreen: PrismMainDashboard(),
                              ),
                              SizedBox(width: isWide ? 40 : 0, height: isWide ? 0 : 40), // Amplified gutters

                              _buildActionCard(
                                context: context,
                                title: "EDIT",
                                highlightedWord: "Inventory",
                                subtitle: "Manage stock or shipped packages",
                                imgIcon: Image.asset(
                                  'asset/edit.png',
                                  width: 110,
                                  height: 110,
                                ),
                                iconColor: Colors.grey.shade700,
                                targetScreen: ScanHandlerScreen(),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 80),

                      // 4. Interactive Action Entry Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1B54).withValues(alpha: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 22), // Taller and broader touch target
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          side: const BorderSide(color: Colors.white24),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  // Action Selection Card Builder customized for large displays
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String highlightedWord,
    required String subtitle,
    required Image imgIcon,
    required Color iconColor,
    required Widget targetScreen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: Container(
        width: 360, // Expanded width base from 260 to fit large aspect ratios beautifully
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: imgIcon,
            ),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$title ",
                    style: TextStyle(
                      fontSize: 28, // Upscaled font sizing
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  TextSpan(
                    text: highlightedWord,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}