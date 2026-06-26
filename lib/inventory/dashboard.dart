import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'inventory.dart';

class PrismMainDashboard extends StatefulWidget {
  final String userCode;
  final String userSubCode;

  const PrismMainDashboard({
    super.key,
    required this.userCode,
    required this.userSubCode,
  });

  @override
  State<PrismMainDashboard> createState() => _PrismMainDashboardState();
}

class _PrismMainDashboardState extends State<PrismMainDashboard> {
  static const Color navNavy = Color(0xFF0C245E);

  // Tracks the current selected panel index (0 = Dashboard, 1 = Inventory, 2 = Settings)
  int _activePageIndex = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _passedInventoryFilter;

  String _getCurrentSystemDate() {
    final now = DateTime.now();

    final weekdays = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    String weekday = weekdays[now.weekday % 7];
    String month = months[now.month - 1];

    return "$weekday, $month ${now.day}, ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // ==========================================
          // PART A: SIDEBAR PANEL COMPONENT
          // ==========================================
          Container(
            width: 420,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 48.0, left: 40.0, right: 40.0, bottom: 24.0),
                  child: Row(
                    children: [
                      Image.asset('asset/MLA.png', height: 56, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 40, color: navNavy)),
                      const SizedBox(width: 16),
                      const Text(
                        "Inventory",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: navNavy),
                      )
                    ],
                  ),
                ),
                const Divider(thickness: 1.5),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, ${widget.userCode}",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userSubCode,
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),

                _buildSidebarRoute(index: 0, icon: Icons.home_outlined, title: "Dashboard"),
                _buildSidebarRoute(index: 1, icon: Icons.inventory_2_outlined, title: "Inventory"),
                _buildSidebarRoute(index: 2, icon: Icons.settings_outlined, title: "Settings"),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: navNavy, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 20),
                          const Text(
                            "Logout",
                            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1.5),

          // ==========================================
          // PART B: WORKSPACE VIEW CONTROLLER
          // ==========================================
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 85,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  alignment: Alignment.centerRight,
                  child: Text(
                    _getCurrentSystemDate(),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const Divider(height: 1, thickness: 1.2),

                Expanded(
                  child: _activePageIndex == 1
                      ? PrismInventoryPage(
                    userCode: widget.userCode,
                    initialStatusFilter: _passedInventoryFilter,
                  )
                      : _activePageIndex == 2
                      ? _buildSettingsWorkspace()
                      : _buildDashboardWorkspace(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsWorkspace() {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'admin_default';

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUid).snapshots(),
      builder: (context, snapshot) {
        String fullName = "";
        String emailAddress = FirebaseAuth.instance.currentUser?.email ?? "";
        String userRole = "Administrator";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          fullName = data['fullName'] ?? fullName;
          emailAddress = data['email'] ?? emailAddress;
          userRole = data['role'] ?? userRole;
        }

        final nameController = TextEditingController(text: fullName);
        final emailController = TextEditingController(text: emailAddress);
        final roleController = TextEditingController(text: userRole);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Settings",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 6),
              Text(
                "Manage your account and Kiosk Settings",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 36),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Row(
                        children: const [
                          Icon(Icons.settings_outlined, color: Colors.black87, size: 26),
                          SizedBox(width: 14),
                          Text(
                            "Profile Information",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),

                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSettingsLabel("Full Name"),
                          const SizedBox(height: 8),
                          _buildSettingsInputField(controller: nameController, hint: "Admin Name"),
                          const SizedBox(height: 24),

                          _buildSettingsLabel("Email Address"),
                          const SizedBox(height: 8),
                          _buildSettingsInputField(controller: emailController, hint: "Enter email address", isReadOnly: true),
                          const SizedBox(height: 24),

                          _buildSettingsLabel("Role"),
                          const SizedBox(height: 8),
                          _buildSettingsInputField(controller: roleController, hint: "Staff / Admin pointer role type profile details", isReadOnly: true),

                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _firestore.collection('users').doc(currentUid).set({
                                  'fullName': nameController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'role': roleController.text.trim(),
                                }, SetOptions(merge: true));

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile information updated successfully!')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Save Profile Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 36),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Row(
                        children: const [
                          Icon(Icons.lock_outline_rounded, color: Colors.black87, size: 26),
                          SizedBox(width: 14),
                          Text(
                            "Security",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                          )
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1.2),
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              if (emailAddress.isNotEmpty) {
                                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailAddress);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Password reset link dispatched directly to $emailAddress')),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Change Password",
                              style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
    );
  }

  Widget _buildSettingsInputField({
    required TextEditingController controller,
    required String hint,
    bool isReadOnly = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        style: TextStyle(color: isReadOnly ? Colors.grey.shade500 : Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildDashboardWorkspace() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('master_list').snapshots(),
      builder: (context, snapshot) {
        int uniqueItemsCount = 0;
        int totalPhysicalQuantity = 0;
        int lowStock = 0;
        int outOfStock = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          uniqueItemsCount = docs.length;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int quantity = data['quantity'] ?? 0;
            final String rawMin = data['minLimit'] ?? "Min: 10";

            final int parsedMinLimit = int.tryParse(rawMin.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;

            totalPhysicalQuantity += quantity;

            if (quantity <= 0) {
              outOfStock++;
            } else if (quantity < parsedMinLimit) {
              lowStock++;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${widget.userCode}",
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 6),
              Text(
                "Here's what's happening with your inventory",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 36),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Total Items Types",
                      count: uniqueItemsCount.toString(),
                      icon: Icons.inventory_2_outlined,
                      badgeColor: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildMetricCard(
                      title: "Total Units Quantity",
                      count: totalPhysicalQuantity.toString(),
                      icon: Icons.layers_outlined,
                      badgeColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 24),

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _passedInventoryFilter = "Low Stock";
                          _activePageIndex = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMetricCard(
                        title: "Low Stock Items",
                        count: lowStock.toString(),
                        icon: Icons.lightbulb_outline,
                        badgeColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _passedInventoryFilter = "Out of Stock";
                          _activePageIndex = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMetricCard(
                        title: "Out of Stock Items",
                        count: outOfStock.toString(),
                        icon: Icons.trending_up_sharp,
                        badgeColor: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Activity Feed
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 520,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Recent Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          const Divider(),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore.collection('activities').orderBy('timestamp', descending: true).limit(4).snapshots(),
                              builder: (context, actSnapshot) {
                                if (!actSnapshot.hasData) return const Center(child: LinearProgressIndicator());

                                return ListView.separated(
                                  itemCount: actSnapshot.data!.docs.length,
                                  separatorBuilder: (_, _) => const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    var doc = actSnapshot.data!.docs[index];
                                    final data = doc.data() as Map<String, dynamic>;

                                    String itemName = data['itemName'] ?? '';
                                    String refNumber = data['refNumber'] ?? '';
                                    int qty = data['qty'] ?? 0;
                                    String dateString = data['dateString'] ?? '';

                                    // Deduce transactional state variations
                                    String statusStr = (data['status'] ?? '').toString().toLowerCase();
                                    bool isSubtraction = qty < 0 ||
                                        statusStr.contains('shipped') ||
                                        statusStr.contains('minus') ||
                                        statusStr.contains('sub') ||
                                        statusStr.contains('out');

                                    String qtyDisplay;
                                    Color deltaColor;
                                    if (isSubtraction) {
                                      qtyDisplay = "-${qty.abs()}";
                                      deltaColor = Colors.red.shade700;
                                    } else {
                                      qtyDisplay = "+$qty";
                                      deltaColor = Colors.green.shade700;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      key: ValueKey(doc.id),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(itemName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                                              const SizedBox(height: 4),
                                              Text(refNumber, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Qty: $qtyDisplay",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                  color: deltaColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(dateString, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                            ],
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _activePageIndex = 1;
                                });
                              },
                              child: const Text("View All Items", style: TextStyle(color: navNavy, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Alerts panel
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 520,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alerts & Notification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          _buildStatusBanner(
                            title: "Out of Stock Items",
                            subtitle: outOfStock == 1 ? "1 item is out of stock" : "$outOfStock items are out of stock",
                            bgColor: const Color(0xFFFEE2E2),
                            accentColor: const Color(0xFFEF4444),
                            icon: Icons.warning_amber_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusBanner(
                            title: "Low Stock Warning",
                            subtitle: lowStock == 1 ? "1 item needs restocking" : "$lowStock items need restocking",
                            bgColor: const Color(0xFFFEF3C7),
                            accentColor: const Color(0xFFD97706),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarRoute({required int index, required IconData icon, required String title}) {
    bool isActive = _activePageIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activePageIndex = index;
          _passedInventoryFilter = null;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 40),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF3F4F6) : Colors.transparent,
          border: isActive ? const Border(right: BorderSide(color: navNavy, width: 6)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? navNavy : Colors.grey.shade600, size: 32),
            const SizedBox(width: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.black : Colors.grey.shade700,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 24),
          Text(count, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: accentColor.withValues(alpha: 0.8), fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}