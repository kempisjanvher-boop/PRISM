import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const Color navNavy = Color(0xFF0C245E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('inventory').snapshots(),
      builder: (context, snapshot) {
        int totalSKUs = 0;
        int categories = 0;
        int totalUnits = 0;
        Map<String, int> categoryCount = {};
        Map<String, int> statusCount = {'In stock': 0, 'Low Stock': 0, 'Out of Stock': 0};

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalSKUs = docs.length;
          Set<String> uniqueCategories = {};
          
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            String category = data['category'] ?? 'Uncategorized';
            int quantity = data['quantity'] ?? 0;
            String status = data['status'] ?? 'In stock';
            
            uniqueCategories.add(category);
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
            totalUnits += quantity;
            
            // Match dashboard logic: exact match for Low Stock and Out of Stock, everything else is In stock
            if (status == "Low Stock") {
              statusCount['Low Stock'] = (statusCount['Low Stock'] ?? 0) + 1;
            } else if (status == "Out of Stock") {
              statusCount['Out of Stock'] = (statusCount['Out of Stock'] ?? 0) + 1;
            } else {
              statusCount['In stock'] = (statusCount['In stock'] ?? 0) + 1;
            }
          }
          categories = uniqueCategories.length;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Reports & Analytics", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("Inventory insights and statistics", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: navNavy,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: navNavy.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report exported successfully')),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text("Export Report", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF0369A1), size: 32),
                          ),
                          const SizedBox(height: 24),
                          Text(totalSKUs.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Total SKUs", style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.category_outlined, color: Color(0xFFD97706), size: 32),
                          ),
                          const SizedBox(height: 24),
                          Text(categories.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Categories", style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.widgets_outlined, color: Color(0xFF16A34A), size: 32),
                          ),
                          const SizedBox(height: 24),
                          Text(totalUnits.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Total Units", style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Charts Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bar Chart - Inventory by Category
                  Expanded(
                    child: Container(
                      height: 450,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Inventory by Category", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: categoryCount.isEmpty
                                ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: categoryCount.values.reduce((a, b) => a > b ? a : b).toDouble() + 5,
                                      barTouchData: BarTouchData(enabled: true),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final categories = categoryCount.keys.toList();
                                              if (value.toInt() >= 0 && value.toInt() < categories.length) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(
                                                    categories[value.toInt()],
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(fontSize: 11),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: categoryCount.entries.map((entry) {
                                        final index = categoryCount.keys.toList().indexOf(entry.key);
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: entry.value.toDouble(),
                                              color: navNavy,
                                              width: 40,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Pie Chart - Stock Status Distribution
                  Expanded(
                    child: Container(
                      height: 450,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Stock Status Distribution", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: statusCount.values.every((v) => v == 0)
                                ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 60,
                                      sections: [
                                        PieChartSectionData(
                                          value: statusCount['In stock']?.toDouble() ?? 0,
                                          title: '${statusCount['In stock'] ?? 0}',
                                          color: const Color(0xFF16A34A),
                                          radius: 50,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        PieChartSectionData(
                                          value: statusCount['Low Stock']?.toDouble() ?? 0,
                                          title: '${statusCount['Low Stock'] ?? 0}',
                                          color: const Color(0xFFD97706),
                                          radius: 50,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        PieChartSectionData(
                                          value: statusCount['Out of Stock']?.toDouble() ?? 0,
                                          title: '${statusCount['Out of Stock'] ?? 0}',
                                          color: const Color(0xFFEF4444),
                                          radius: 50,
                                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _buildLegend('In stock', const Color(0xFF16A34A)),
                          _buildLegend('Low Stock', const Color(0xFFD97706)),
                          _buildLegend('Out of Stock', const Color(0xFFEF4444)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Category Summary Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: const Text("Category Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      color: const Color(0xFFEFEFF4),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Total Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        ],
                      ),
                    ),
                    if (categoryCount.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text("No data available", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryCount.entries.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = categoryCount.entries.elementAt(index);
                          return _buildCategoryRow(
                            category: entry.key,
                            items: entry.value.toString(),
                            totalQuantity: _getCategoryTotalQuantity(entry.key, snapshot.data?.docs ?? []).toString(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  int _getCategoryTotalQuantity(String category, List<dynamic> docs) {
    int total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['category'] == category) {
        total += (data['quantity'] ?? 0) as int;
      }
    }
    return total;
  }

  Widget _buildCategoryRow({
    required String category,
    required String items,
    required String totalQuantity,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(category, style: const TextStyle(fontSize: 16, color: Colors.black)),
          ),
          Expanded(flex: 2, child: Text(items, style: const TextStyle(fontSize: 15, color: Colors.grey))),
          Expanded(flex: 2, child: Text(totalQuantity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }
}
