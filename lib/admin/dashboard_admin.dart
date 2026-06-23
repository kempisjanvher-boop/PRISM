import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../inventory/inventory.dart';
import 'users_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';

class PrismAdminDashboard extends StatefulWidget {
  final String userCode;
  final String userSubCode;

  const PrismAdminDashboard({
    super.key,
    required this.userCode,
    required this.userSubCode,
  });

  @override
  State<PrismAdminDashboard> createState() => _PrismAdminDashboardState();
}

class _PrismAdminDashboardState extends State<PrismAdminDashboard> {
  static const Color navNavy = Color(0xFF0C245E);
  int _activePageIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getCurrentSystemDate() {
    final now = DateTime.now();
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return "${weekdays[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // Sidebar Panel
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
                      const Text("Inventory", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: navNavy))
                    ],
                  ),
                ),
                const Divider(thickness: 1.5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Welcome, Admin User", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.userSubCode, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                _buildSidebarRoute(index: 0, icon: Icons.home_outlined, title: "Dashboard"),
                _buildSidebarRoute(index: 1, icon: Icons.inventory_2_outlined, title: "Inventory"),
                _buildSidebarRoute(index: 2, icon: Icons.person_outline, title: "Users"),
                _buildSidebarRoute(index: 3, icon: Icons.assignment_outlined, title: "Reports"),
                _buildSidebarRoute(index: 4, icon: Icons.settings_outlined, title: "Settings"),
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
                      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: navNavy, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
                          const SizedBox(width: 20),
                          const Text("Logout", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1.5),
          // Content Workspace
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 85, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40.0), alignment: Alignment.centerRight,
                  child: Text(_getCurrentSystemDate(), style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                const Divider(height: 1, thickness: 1.2),
                Expanded(
                  child:
                  IndexedStack(
                    index: _activePageIndex,
                    children: [
                      _buildDashboardWorkspace(),
                      PrismInventoryPage(userCode: widget.userCode),
                      const UsersPage(),
                      const ReportsPage(),
                      const SettingsPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardWorkspace() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('inventory').snapshots(),
      builder: (context, snapshot) {
        int uniqueItemsCount = 0;
        int lowStock = 0;
        int outOfStock = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          uniqueItemsCount = docs.length;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String status = data['status'] ?? 'In stock';
            if (status == "Low Stock") lowStock++;
            if (status == "Out of Stock") outOfStock++;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome, Admin User", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Here's what's happening with your inventory", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 36),

              // 3-Column Metrics Row
              Row(
                children: [
                  Expanded(child: _buildMetricCard(title: "Total items", count: uniqueItemsCount.toString(), icon: Icons.inventory_2_outlined, badgeColor: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0369A1))),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMetricCard(title: "Low Stock", count: lowStock.toString(), icon: Icons.error_outline_rounded, badgeColor: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706))),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMetricCard(title: "Out of Stock", count: outOfStock.toString(), icon: Icons.trending_up_sharp, badgeColor: const Color(0xFFFEE2E2), iconColor: const Color(0xFFEF4444))),
                ],
              ),
              const SizedBox(height: 36),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // LIVE EMPLOYEE MONITORING FEED PANELS
                  // ==========================================
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 520,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Recent Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          const Divider(),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              // Fetches ALL absolute actions across the system globally ordered chronologically
                              stream: _firestore.collection('activities').orderBy('timestamp', descending: true).limit(5).snapshots(),
                              builder: (context, actSnapshot) {
                                if (!actSnapshot.hasData) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(navNavy)));
                                if (actSnapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text("No transaction logs recorded from standard operators yet.", style: TextStyle(color: Colors.grey)));
                                }

                                return ListView.separated(
                                  itemCount: actSnapshot.data!.docs.length,
                                  separatorBuilder: (_, __) => const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    var doc = actSnapshot.data!.docs[index];
                                    final data = doc.data() as Map<String, dynamic>;

                                    // Extract data variables cleanly
                                    String itemName = data['itemName'] ?? 'Unknown Item';
                                    String refNumber = data['refNumber'] ?? 'N/A';
                                    int qty = data['qty'] ?? 0;
                                    String dateString = data['dateString'] ?? '';

                                    // Capture who completed the task for auditing visibility
                                    String employeeName = data['createdBy'] ?? data['userCode'] ?? data['usercode'] ?? 'N/A';

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      key: ValueKey(doc.id),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text("Ref: $refNumber", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                                                    child: Text(
                                                      "By: $employeeName",
                                                      style: const TextStyle(color: navNavy, fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text("Qty: $qty", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87)),
                                              const SizedBox(height: 6),
                                              Text(dateString, style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _activePageIndex = 1),
                              child: const Text("View All Items", style: TextStyle(color: navNavy, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Alerts Panel Block
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 520, padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alerts & Notification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          _buildStatusBanner(title: "Out of Stock Items", subtitle: "$outOfStock item is out of stock", bgColor: const Color(0xFFFEE2E2), accentColor: const Color(0xFFEF4444)),
                          const SizedBox(height: 16),
                          _buildStatusBanner(title: "Low Stock Warning", subtitle: "$lowStock item needs restocking", bgColor: const Color(0xFFFEF3C7), accentColor: const Color(0xFFD97706)),
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
      onTap: () => setState(() => _activePageIndex = index),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFF3F4F6) : Colors.transparent, border: isActive ? const Border(right: BorderSide(color: navNavy, width: 6)) : null),
        child: Row(children: [Icon(icon, color: isActive ? navNavy : Colors.grey.shade600, size: 30), const SizedBox(width: 24), Text(title, style: TextStyle(fontSize: 20, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.black : Colors.grey.shade700))]),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String count, required IconData icon, required Color badgeColor, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 32)), const SizedBox(height: 24), Text(count, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 15))]),
    );
  }

  Widget _buildStatusBanner({required String title, required String subtitle, required Color bgColor, required Color accentColor}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.warning_amber_rounded, color: accentColor, size: 24), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))]))]),
    );
  }
}