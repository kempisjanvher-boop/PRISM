import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'scan_handler.dart';

class PrismOnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fullscreen Background Image with Dark Blue Overlay Gradient
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('asset/onboarding.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          // 2. Foreground Layout Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding Header Block
                      // Branding Header Block
                      Image.asset(
                        'asset/MLA.png', // Ensure this matches your asset file name and path
                        height: 110,          // Adjusted to fit neatly within the onboarding layout
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: "Hello, Welcome to ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: "MLA.Digital",
                              style: TextStyle(
                                color: const Color(0xFF0F1B54), // Matches the exact dark blue brand color
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Prompt Text
                      Text(
                        "What do you want today?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 30),

                      // 3. Selection Action Cards (Responsive layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 600;
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
                                  width: 65,
                                  height: 65,
                                ),
                                iconColor: Colors.grey.shade700,
                                targetScreen: PrismMainDashboard(),
                              ),
                              SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                              // Edit Inventory Card
                              _buildActionCard(
                                context: context,
                                title: "EDIT",
                                highlightedWord: "Inventory",
                                subtitle: "Manage stock or shipped packages",
                                imgIcon: Image.asset(
                                  'asset/edit.png',
                                  width: 65,
                                  height: 65,
                                ),
                                iconColor: Colors.grey.shade700,
                                targetScreen: ScanHandlerScreen(),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 40),

                      // 4. Auxiliary Authentic Sign-In Action
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Sign In administrative module locked.")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade900.withOpacity(0.8),
                          padding: EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(color: Colors.white24),
                        ),
                        child: Text(
                          "Sign In",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
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

  // Action Selection Card Builder matching image_dc382c.jpg design variables
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
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            SizedBox(
              width: 65,
              height: 65,
              child: imgIcon,
            ),

            const SizedBox(height: 16),

            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$title ",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  TextSpan(
                    text: highlightedWord,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}