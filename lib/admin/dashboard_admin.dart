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

  // Track active filter payloads clicked from metric cards
  String? _passedInventoryFilter;

  String _getCurrentSystemDate() {
    final now = DateTime.now();
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return "${weekdays[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}, ${now.year}";
  }

  // Helper method used to dynamically generate current MM-DD-YYYY strings when adding logs
  String _generateActivityDateString() {
    final now = DateTime.now();
    String month = now.month.toString().padLeft(2, '0');
    String day = now.day.toString().padLeft(2, '0');
    String year = now.year.toString();
    return "$month-$day-$year";
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
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 310),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 36.0, left: 24.0, right: 24.0, bottom: 20.0),
                  child: Row(
                    children: [
                      Image.asset('asset/MLA.png', height: 44, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.apps, size: 32, color: navNavy)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Inventory",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navNavy),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(thickness: 1.5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome, Admin User", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(widget.userSubCode, style: TextStyle(fontSize: 15, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
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
                  padding: const EdgeInsets.all(24.0),
                  child: InkWell(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: navNavy, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white, size: 16)),
                          const SizedBox(width: 14),
                          const Text("Logout", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
          // PART B: CONTENT WORKSPACE VIEW CONTROLLER
          // ==========================================
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32.0), alignment: Alignment.centerRight,
                  child: Text(_getCurrentSystemDate(), style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                const Divider(height: 1, thickness: 1.2),
                Expanded(
                  child: IndexedStack(
                    index: _activePageIndex,
                    children: [
                      _buildDashboardWorkspace(),
                      PrismInventoryPage(
                        key: ValueKey('admin_inv_filter_${_passedInventoryFilter ?? "none"}'),
                        userCode: widget.userCode,
                        initialStatusFilter: _passedInventoryFilter,
                      ),
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
      stream: _firestore.collection('master_list').snapshots(),
      builder: (context, snapshot) {
        int uniqueItemsCount = 0;
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

            if (quantity <= 0) {
              outOfStock++;
            } else if (quantity < parsedMinLimit) {
              lowStock++;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome, Admin User", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Here's what's happening with your inventory", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = (constraints.maxWidth - (16 * 2)) / 3;
                  if (cardWidth < 140) cardWidth = 140;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildMetricCard(title: "Total items", count: uniqueItemsCount.toString(), icon: Icons.inventory_2_outlined, badgeColor: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0369A1)),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _passedInventoryFilter = "Low Stock";
                              _activePageIndex = 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: _buildMetricCard(title: "Low Stock", count: lowStock.toString(), icon: Icons.error_outline_rounded, badgeColor: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706)),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _passedInventoryFilter = "Out of Stock";
                              _activePageIndex = 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: _buildMetricCard(title: "Out of Stock", count: outOfStock.toString(), icon: Icons.trending_up_sharp, badgeColor: const Color(0xFFFEE2E2), iconColor: const Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Activity Feed Panel
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 500,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Recent Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          const Divider(),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore.collection('activities').orderBy('timestamp', descending: true).limit(15).snapshots(),
                              builder: (context, actSnapshot) {
                                if (!actSnapshot.hasData) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(navNavy)));
                                if (actSnapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text("No transaction logs recorded from standard operators yet.", style: TextStyle(color: Colors.grey)));
                                }

                                return ListView.separated(
                                  itemCount: actSnapshot.data!.docs.length,
                                  padding: EdgeInsets.zero,
                                  physics: const ClampingScrollPhysics(),
                                  separatorBuilder: (_, _) => const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    var doc = actSnapshot.data!.docs[index];
                                    final data = doc.data() as Map<String, dynamic>;

                                    String itemName = data['itemName'] ?? 'Unknown Item';
                                    String refNumber = data['refNumber'] ?? 'N/A';
                                    int qty = data['qty'] ?? 0;
                                    String employeeName = data['createdBy'] ?? data['userCode'] ?? data['usercode'] ?? 'N/A';

                                    String dateString = '';
                                    dynamic rawDate = data['dateString'];
                                    if (rawDate is Timestamp) {
                                      DateTime dt = rawDate.toDate();
                                      String m = dt.month.toString().padLeft(2, '0');
                                      String d = dt.day.toString().padLeft(2, '0');
                                      dateString = "$m-$d-${dt.year}";
                                    } else {
                                      dateString = rawDate?.toString() ?? '';
                                    }

                                    String statusStr = (data['status'] ?? '').toString().toLowerCase().trim();

                                    bool isSubtraction = qty < 0 ||
                                        statusStr.contains('ship') ||
                                        statusStr.contains('minus') ||
                                        statusStr.contains('sub') ||
                                        statusStr.contains('deduct') ||
                                        statusStr.contains('out');

                                    String qtyDisplay = isSubtraction ? "-${qty.abs()}" : "+$qty";
                                    Color deltaColor = isSubtraction ? Colors.red.shade700 : Colors.green.shade700;

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
                                              Text(
                                                "Qty: $qtyDisplay",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: deltaColor),
                                              ),
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
                              onPressed: () {
                                setState(() {
                                  _passedInventoryFilter = null;
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
                  const SizedBox(width: 20),

                  // Alerts Panel Block
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 500,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Alerts & Notification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildStatusBanner(title: "Out of Stock Items", subtitle: outOfStock == 1 ? "1 item is out of stock" : "$outOfStock items are out of stock", bgColor: const Color(0xFFFEE2E2), accentColor: const Color(0xFFEF4444)),
                          const SizedBox(height: 12),
                          _buildStatusBanner(title: "Low Stock Warning", subtitle: lowStock == 1 ? "1 item needs restocking" : "$lowStock items need restocking", bgColor: const Color(0xFFFEF3C7), accentColor: const Color(0xFFD97706)),
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
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFF3F4F6) : Colors.transparent, border: isActive ? const Border(right: BorderSide(color: navNavy, width: 5)) : null),
        child: Row(
          children: [
            Icon(icon, color: isActive ? navNavy : Colors.grey.shade600, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.black : Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String count, required IconData icon, required Color badgeColor, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 16),
          Text(count, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)
        ],
      ),
    );
  }

  Widget _buildStatusBanner({required String title, required String subtitle, required Color bgColor, required Color accentColor}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
              ],
            ),
          )
        ],
      ),
    );
  }
}