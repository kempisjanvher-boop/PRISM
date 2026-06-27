import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './accounts/login_screen.dart';

class PrismMainDashboard extends StatefulWidget {
  const PrismMainDashboard({super.key});

  @override
  State<PrismMainDashboard> createState() => _PrismMainDashboardState();
}

class _PrismMainDashboardState extends State<PrismMainDashboard> {
  static const Color navNavy = Color(0xFF0C245E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategoryFilter = "All Categories";
  String _selectedStatusFilter = "All Status";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _promptAuthentication() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white),
            SizedBox(width: 12),
            Text("Action Restricted: Please sign in to modify inventory records."),
          ],
        ),
        backgroundColor: navNavy,
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 32.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- APP BAR ACTIONS LAYOUT WITH BACK BUTTON ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Large, tap-friendly Back Arrow customized for tablet interfaces
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
                        onPressed: () => Navigator.pop(context),
                        tooltip: "Back to Main Screen",
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 16),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Live Inventory Sync", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 4),
                          Text("Read-only operational tracking layout", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _promptAuthentication,
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: const Text("Staff Login", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: navNavy,
                      side: const BorderSide(color: navNavy, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // --- FILTER & ENGINE MANAGEMENT ROW ---
              Row(
                children: [
                  Expanded(
                    flex: isLandscape ? 2 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                          hintText: "Search items...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => _searchController.clear())
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRealDropdownFilter(
                      prefixIcon: Icons.filter_alt_outlined,
                      currentValue: _selectedCategoryFilter,
                      items: ["All Categories", "Office Supplies", "Electrical", "Accessories", "Tools"],
                      onChanged: (val) => setState(() => _selectedCategoryFilter = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRealDropdownFilter(
                      prefixIcon: Icons.playlist_add_check,
                      currentValue: _selectedStatusFilter,
                      items: ["All Status", "In stock", "Low Stock", "Out of Stock"],
                      onChanged: (val) => setState(() => _selectedStatusFilter = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- DATA SHEET GRID LAYER ---
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xFFEFEFF4),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Ref Num", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              SizedBox(width: 40),
                            ],
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore.collection('master_list').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              if (snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text("No items currently tracked in the master inventory."));
                              }

                              final filteredDocs = snapshot.data!.docs.where((doc) {
                                final Object? rawData = doc.data();
                                if (rawData == null || rawData is! Map<String, dynamic>) return false;
                                final Map<String, dynamic> data = rawData;

                                final String name = (data['name'] ?? '').toString().toLowerCase();
                                final String refNum = (data['refNum'] ?? '').toString().toLowerCase();
                                final String category = (data['category'] ?? 'General').toString();

                                final int qty = data['quantity'] ?? 0;
                                final String rawMin = data['minLimit'] ?? 'Min: 10';
                                final int minLimit = int.tryParse(rawMin.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;

                                String computedStatus = "In stock";
                                if (qty <= 0) {
                                  computedStatus = "Out of Stock";
                                } else if (qty < minLimit) computedStatus = "Low Stock";

                                final bool matchesSearch = name.contains(_searchQuery) || refNum.contains(_searchQuery);
                                final bool matchesCategory = _selectedCategoryFilter == "All Categories" || category == _selectedCategoryFilter;
                                final bool matchesStatus = _selectedStatusFilter == "All Status" || computedStatus == _selectedStatusFilter;

                                return matchesSearch && matchesCategory && matchesStatus;
                              }).toList();

                              if (filteredDocs.isEmpty) {
                                return const Center(child: Text("No items match your search criteria."));
                              }

                              return ListView.separated(
                                itemCount: filteredDocs.length,
                                padding: EdgeInsets.zero,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  var doc = filteredDocs[index];
                                  final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                                  final int liveQty = data['quantity'] ?? 0;
                                  final String rawMinLimit = data['minLimit'] ?? 'Min: 10';
                                  final int parsedMinLimit = int.tryParse(rawMinLimit.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;

                                  String computedStatus = "In stock";
                                  Color statusBg = const Color(0xFFE8F5E9);
                                  Color statusText = const Color(0xFF2E7D32);

                                  if (liveQty <= 0) {
                                    computedStatus = "Out of Stock";
                                    statusBg = const Color(0xFFFFEBEE);
                                    statusText = const Color(0xFFC62828);
                                  } else if (liveQty < parsedMinLimit) {
                                    computedStatus = "Low Stock";
                                    statusBg = const Color(0xFFFFF3E0);
                                    statusText = const Color(0xFFEF6C00);
                                  }

                                  return _buildInventoryRow(
                                    name: data['name'] ?? '',
                                    refNum: data['refNum'] ?? '',
                                    category: data['category'] ?? '',
                                    qty: liveQty.toString(),
                                    minLimit: rawMinLimit,
                                    statusText: computedStatus,
                                    statusColor: statusBg,
                                    textColor: statusText,
                                    isIncrement: data['isIncrement'] ?? false,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealDropdownFilter({
    required IconData prefixIcon,
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Icon(prefixIcon, color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                items: items.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRow({
    required String name,
    required String refNum,
    required String category,
    required String qty,
    required String minLimit,
    required String statusText,
    required Color statusColor,
    required Color textColor,
    required bool isIncrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(isIncrement ? Icons.add : Icons.remove, color: isIncrement ? const Color(0xFF2E7D32) : const Color(0xFFC62828), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 16, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(refNum, style: TextStyle(color: Colors.grey.shade600, fontSize: 15))),
          Expanded(flex: 2, child: Text(category, style: TextStyle(color: Colors.grey.shade600, fontSize: 15))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Text(minLimit, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.grey),
            onPressed: _promptAuthentication,
          )
        ],
      ),
    );
  }
}