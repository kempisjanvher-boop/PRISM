import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const Color navNavy = Color(0xFF0C245E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track user-selected calendar date filter
  DateTime? _selectedDate;

  // Screenshot Controllers to capture structural charts
  final ScreenshotController _barChartController = ScreenshotController();
  final ScreenshotController _pieChartController = ScreenshotController();

  String _formatDateTime(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: navNavy,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // --- EXPORT CURRENT LIVE INVENTORY STOCK REPORT ---
  Future<void> _exportCurrentStockReport() async {
    try {
      final querySnapshot = await _firestore.collection('master_list').get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No live inventory records found to compile.")),
        );
        return;
      }

      final pdf = pw.Document();
      final PdfColor navyColor = PdfColor.fromHex('0C245E');

      final List<List<String>> tableData = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        tableData.add([
          data['refNum'] ?? '',
          data['name'] ?? '',
          data['category'] ?? '',
          (data['quantity'] ?? 0).toString(),
          (data['status'] ?? 'In stock').toUpperCase(),
        ]);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PRISM INVENTORY SYSTEM", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: navyColor)),
                      pw.SizedBox(height: 4),
                      pw.Text("Live System Stock Status Report Summary", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()), style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 2, color: navyColor),
              pw.SizedBox(height: 20),

              pw.TableHelper.fromTextArray(
                headers: ['Reference No.', 'Item Description', 'Category', 'Qty Available', 'Status Flag'],
                data: tableData,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                headerDecoration: pw.BoxDecoration(color: navyColor),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
              ),

              pw.SizedBox(height: 30),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Total Unique Line Items Listed: ${tableData.length}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: navyColor),
                ),
              )
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Inventory_Stock_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate stock summary: $e')),
      );
    }
  }

  // --- COMPREHENSIVE PDF GENERATOR ENGINE (TRANSACTIONS) ---
  Future<void> _exportDocumentReport({
    required List<QueryDocumentSnapshot> transactions,
  }) async {
    try {
      final Uint8List? barImageBytes = await _barChartController.capture();
      final Uint8List? pieImageBytes = await _pieChartController.capture();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Inventory Reports & Analytics", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('0C245E'))),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _selectedDate == null
                            ? "All-Time Master Transaction Activity History"
                            : "Filtered Target Date: ${_formatDateTime(_selectedDate!)}",
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()), style: const pw.TextStyle(color: PdfColors.grey600)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColor.fromHex('0C245E'), thickness: 1.5),
              pw.SizedBox(height: 24),

              pw.Text("Visual Data Performance Layouts", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (barImageBytes != null)
                    pw.Container(
                      width: 250,
                      height: 180,
                      child: pw.Image(pw.MemoryImage(barImageBytes)),
                    ),
                  if (pieImageBytes != null)
                    pw.Container(
                      width: 250,
                      height: 180,
                      child: pw.Image(pw.MemoryImage(pieImageBytes)),
                    ),
                ],
              ),
              pw.SizedBox(height: 32),

              pw.Text("Live Item Activity Records Feed Table", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('0C245E')),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Timestamp / Time', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item Description', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Ref No.', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Operator Code', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty Delta', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),

                  ...transactions.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    String displayDate = 'N/A';
                    if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                      DateTime localDate = (data['timestamp'] as Timestamp).toDate().toLocal();
                      displayDate = DateFormat('MMMM dd, yyyy HH:mm').format(localDate);
                    } else if (data['dateString'] != null) {
                      displayDate = data['dateString'];
                    }

                    int qty = (data['qty'] ?? 0) as int;
                    String statusStr = (data['status'] ?? '').toString().toLowerCase();
                    bool isSubtraction = qty < 0 || statusStr == 'shipped' || statusStr == 'minus' || statusStr == 'subtract';

                    String qtyText = isSubtraction ? "-${qty.abs()}" : "+$qty";

                    pw.TextStyle rowStyle = pw.TextStyle(
                      color: isSubtraction ? PdfColors.red700 : PdfColors.green700,
                      fontWeight: pw.FontWeight.bold,
                    );

                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(displayDate, style: const pw.TextStyle(color: PdfColors.black))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['itemName'] ?? 'Unknown', style: const pw.TextStyle(color: PdfColors.black))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['refNumber'] ?? 'N/A', style: const pw.TextStyle(color: PdfColors.black))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['createdBy'] ?? data['userCode'] ?? 'N/A', style: const pw.TextStyle(color: PdfColors.black))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(qtyText, style: rowStyle)),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: _selectedDate == null
            ? 'Inventory_Report_AllTime.pdf'
            : 'Report_${DateFormat('yyyy_MM_dd').format(_selectedDate!)}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed compilation processes for graphics engines: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('master_list').orderBy('timestamp', descending: true).snapshots(),
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
            String rawMin = data['minLimit'] ?? "Min: 10";

            final int parsedMinLimit = int.tryParse(rawMin.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;

            uniqueCategories.add(category);
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
            totalUnits += quantity;

            if (quantity <= 0) {
              statusCount['Out of Stock'] = (statusCount['Out of Stock'] ?? 0) + 1;
            } else if (quantity < parsedMinLimit) {
              statusCount['Low Stock'] = (statusCount['Low Stock'] ?? 0) + 1;
            } else {
              statusCount['In stock'] = (statusCount['In stock'] ?? 0) + 1;
            }
          }
          categories = uniqueCategories.length;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('activities').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, actSnapshot) {
            List<QueryDocumentSnapshot> transactionsForDate = [];

            if (actSnapshot.hasData) {
              for (var doc in actSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                DateTime? tDate;
                if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                  tDate = (data['timestamp'] as Timestamp).toDate().toLocal();
                }

                if (_selectedDate == null) {
                  transactionsForDate.add(doc);
                } else if (tDate != null &&
                    tDate.year == _selectedDate!.year &&
                    tDate.month == _selectedDate!.month &&
                    tDate.day == _selectedDate!.day) {
                  transactionsForDate.add(doc);
                }
              }
            }

            return SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIXED RESPONSIVE WRAPPED HEADER
                    Wrap(
                      spacing: 16,        // Horizontal space between elements
                      runSpacing: 16,     // Vertical space if elements wrap to a new line
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Title block adapts to container sizes safely
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 280),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Reports & Analytics", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("Inventory insights and statistics", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            ],
                          ),
                        ),

                        // Action buttons wrapped inside a flexible flow container
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.calendar_month_outlined, color: navNavy, size: 20),
                              label: Text(
                                _selectedDate == null ? "Select Date" : _formatDateTime(_selectedDate!),
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.white,
                              ),
                            ),
                            if (_selectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.redAccent),
                                tooltip: "Clear Filter",
                                onPressed: () => setState(() => _selectedDate = null),
                              ),

                            // Live Stock Asset Exporter Button
                            OutlinedButton.icon(
                              onPressed: _exportCurrentStockReport,
                              icon: const Icon(Icons.assignment_outlined, color: Colors.green, size: 20),
                              label: const Text(
                                "Export Stock Status",
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                side: const BorderSide(color: Colors.green, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.white,
                              ),
                            ),

                            // Log File Exporter Action Frame
                            Container(
                              decoration: BoxDecoration(
                                color: navNavy,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: navNavy.withAlpha(128), blurRadius: 16, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _exportDocumentReport(transactions: transactionsForDate),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.file_download_outlined, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text("Export Logs", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard("Total SKUs", totalSKUs.toString(), Icons.inventory_2_outlined, const Color(0xFF0369A1), const Color(0xFFE0F2FE))),
                        const SizedBox(width: 24),
                        Expanded(child: _buildSummaryCard("Categories", categories.toString(), Icons.category_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7))),
                        const SizedBox(width: 24),
                        Expanded(child: _buildSummaryCard("Total Units", totalUnits.toString(), Icons.widgets_outlined, const Color(0xFF16A34A), const Color(0xFFDCFCE7))),
                      ],
                    ),
                    const SizedBox(height: 36),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Screenshot(
                            controller: _barChartController,
                            child: Container(
                              height: 450,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 1)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Inventory by Category", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: categoryCount.isEmpty
                                        ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
                                        : BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: categoryCount.values.isEmpty ? 10 : categoryCount.values.reduce((a, b) => a > b ? a : b).toDouble() + 5,
                                        titlesData: FlTitlesData(
                                          show: true,
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 45,
                                              getTitlesWidget: (value, meta) {
                                                final categories = categoryCount.keys.toList();
                                                final index = value.toInt();

                                                if (index >= 0 && index < categories.length) {
                                                  final bool isEven = index % 2 == 0;
                                                  final double topPadding = isEven ? 6.0 : 22.0;

                                                  return Padding(
                                                    padding: EdgeInsets.only(top: topPadding),
                                                    child: Text(
                                                      categories[index],
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                        ),
                                        barGroups: categoryCount.entries.map((entry) {
                                          final index = categoryCount.keys.toList().indexOf(entry.key);
                                          return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: entry.value.toDouble(), color: navNavy, width: 40, borderRadius: BorderRadius.circular(4))]);
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        Expanded(
                          child: Screenshot(
                            controller: _pieChartController,
                            child: Container(
                              height: 450,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 1)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Stock Status Distribution", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
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
                                          PieChartSectionData(value: statusCount['In stock']?.toDouble() ?? 0, title: '${statusCount['In stock'] ?? 0}', color: const Color(0xFF16A34A), radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          PieChartSectionData(value: statusCount['Low Stock']?.toDouble() ?? 0, title: '${statusCount['Low Stock'] ?? 0}', color: const Color(0xFFD97706), radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          PieChartSectionData(value: statusCount['Out of Stock']?.toDouble() ?? 0, title: '${statusCount['Out of Stock'] ?? 0}', color: const Color(0xFFEF4444), radius: 50, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildLegend('In stock', const Color(0xFF16A34A)),
                                      _buildLegend('Low Stock', const Color(0xFFD97706)),
                                      _buildLegend('Out of Stock', const Color(0xFFEF4444)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.all(32), child: Text("Category Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
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
                            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No data available", style: TextStyle(color: Colors.grey))))
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
                    const SizedBox(height: 36),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate == null ? "Global Transaction Log History" : "Transaction History for ${_formatDateTime(_selectedDate!)}",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                if (_selectedDate != null) Text("${transactionsForDate.length} logged items", style: const TextStyle(color: navNavy, fontWeight: FontWeight.bold))
                              ],
                            ),
                          ),
                          Container(
                            color: const Color(0xFFEFEFF4),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: Text("Timestamp / Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Expanded(flex: 3, child: Text("Item Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Expanded(flex: 2, child: Text("Reference No.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Expanded(flex: 2, child: Text("Operator Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Expanded(flex: 1, child: Text("Qty Delta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                              ],
                            ),
                          ),
                          if (transactionsForDate.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(child: Text(_selectedDate == null ? "No activity tracking records located." : "No activities recorded on ${_formatDateTime(_selectedDate!)}.", style: const TextStyle(color: Colors.grey, fontSize: 16))),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactionsForDate.length,
                              padding: EdgeInsets.zero,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final data = transactionsForDate[index].data() as Map<String, dynamic>;

                                String displayDate = 'N/A';
                                if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                                  DateTime localDate = (data['timestamp'] as Timestamp).toDate().toLocal();
                                  displayDate = DateFormat('MMMM dd, yyyy hh:mm a').format(localDate);
                                } else if (data['dateString'] != null) {
                                  displayDate = data['dateString'];
                                }

                                String itemName = data['itemName'] ?? 'Unknown';
                                String refNumber = data['refNumber'] ?? 'N/A';
                                String createdBy = data['createdBy'] ?? data['userCode'] ?? 'N/A';
                                int qty = (data['qty'] ?? 0) as int;

                                // Deduce subtraction vs addition states
                                String statusStr = (data['status'] ?? '').toString().toLowerCase();
                                bool isSubtraction = qty < 0 || statusStr == 'shipped' || statusStr == 'minus' || statusStr == 'subtract';

                                String qtyText;
                                Color deltaColor;
                                if (isSubtraction) {
                                  int absQty = qty.abs();
                                  qtyText = "-$absQty";
                                  deltaColor = Colors.red.shade700;
                                } else {
                                  qtyText = "+$qty";
                                  deltaColor = Colors.green.shade700;
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(displayDate, style: const TextStyle(fontSize: 14, color: Colors.black87))),
                                      Expanded(flex: 3, child: Text(itemName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black))),
                                      Expanded(flex: 2, child: Text(refNumber, style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
                                      Expanded(flex: 2, child: Text(createdBy, style: const TextStyle(fontSize: 14, color: navNavy))),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          qtyText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: deltaColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ));
            },
        );
      },
    );
  }

  // --- SUPPORT HELPER WIDGET METHODS ---
  Widget _buildSummaryCard(String title, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 24),
          Text(count, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildCategoryRow({required String category, required String items, required String totalQuantity}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(category, style: const TextStyle(fontSize: 16, color: Colors.black))),
          Expanded(flex: 2, child: Text(items, style: const TextStyle(fontSize: 15, color: Colors.grey))),
          Expanded(flex: 2, child: Text(totalQuantity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }

  int _getCategoryTotalQuantity(String category, List<dynamic> docs) {
    int total = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['category'] ?? 'Uncategorized') == category) {
        total += (data['quantity'] ?? 0) as int;
      }
    }
    return total;
  }
}