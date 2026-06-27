import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrismInventoryPage extends StatefulWidget {
  final String userCode;
  final String? initialStatusFilter;

  const PrismInventoryPage({
    super.key,
    required this.userCode,
    this.initialStatusFilter,
  });

  @override
  State<PrismInventoryPage> createState() => _PrismInventoryPageState();
}

class _PrismInventoryPageState extends State<PrismInventoryPage> {
  static const Color navNavy = Color(0xFF0C245E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateActivityDateString() {
    final now = DateTime.now();
    String month = now.month.toString().padLeft(2, '0');
    String day = now.day.toString().padLeft(2, '0');
    String year = now.year.toString();
    return "$month-$day-$year";
  }

  int _selectedShortcutIndex = -1;
  bool _isScannerAddingMode = true;

  final FocusNode _globalScannerFocusNode = FocusNode();
  String _scannedBufferContext = "";

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategoryFilter = "All Categories";
  String _selectedStatusFilter = "All Status";

  @override
  void initState() {
    super.initState();

    if (widget.initialStatusFilter != null) {
      _selectedStatusFilter = widget.initialStatusFilter!;
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_globalScannerFocusNode.canRequestFocus) {
        _globalScannerFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _globalScannerFocusNode.dispose();
    super.dispose();
  }

  void _handleHardwareScanInput(String barcodeRef, {required bool isAdding}) async {
    final querySnapshot = await _firestore
        .collection('master_list')
        .where('refNum', isEqualTo: barcodeRef)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docData = querySnapshot.docs.first.data();

      if (!mounted) return;

      _showScanConfirmationModal(
        isAdding: isAdding,
        scannedName: docData['name'] ?? 'Unknown Registered Item',
        scannedRef: barcodeRef,
        scannedCategory: docData['category'] ?? 'General',
        currentQty: docData['quantity'] ?? 0,
        minLimit: 10,
      );
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text("Barcode Not Registered"),
            ],
          ),
          content: Text("The barcode '$barcodeRef' scanned by the BL-W21 does not exist in the master inventory list database registry."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: navNavy, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _showScanActionConfirmationModal({required bool isAdding}) async {
    String mockBarcodeRef = "1234567890123";
    String matchedName = "Package01";
    String matchedCategory = "Tools";
    int currentQty = 0;
    int minLimit = 10;

    final querySnapshot = await _firestore
        .collection('master_list')
        .where('refNum', isEqualTo: mockBarcodeRef)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Invalid Reference Master Profile"),
          content: Text("The simulated barcode reference '$mockBarcodeRef' is not recognized inside your Master registry lists. Please add item rows manually through configuration layers first."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    final docData = querySnapshot.docs.first.data();
    matchedName = docData['name'] ?? matchedName;
    matchedCategory = docData['category'] ?? matchedCategory;
    currentQty = docData['quantity'] ?? 0;

    String rawMin = docData['minLimit'] ?? "Min: 10";
    minLimit = int.tryParse(rawMin.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;

    final nameController = TextEditingController(text: matchedName);
    final refController = TextEditingController(text: mockBarcodeRef);
    final categoryController = TextEditingController(text: matchedCategory);
    final qtyController = TextEditingController(text: isAdding ? "45" : "1");
    final minQtyController = TextEditingController(text: minLimit.toString());

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isAdding ? "Add New Item" : "Ship Item Details",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 24, color: Colors.black87),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                _buildModalLabel("Item Name *"),
                const SizedBox(height: 6),
                _buildModalTextField(controller: nameController, hint: ""),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel("Reference Number *"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: refController, hint: ""),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel("Category*"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: categoryController, hint: ""),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel(isAdding ? "Quantity *" : "Quantity Shipped *"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: qtyController, hint: "", isNumeric: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel("Min Quantity *"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: minQtyController, hint: "", isNumeric: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        final String finalName = nameController.text.trim();
                        final String finalRef = refController.text.trim();
                        final String finalCat = categoryController.text.trim();
                        final int targetDelta = int.tryParse(qtyController.text.trim()) ?? 0;
                        final int targetMin = int.tryParse(minQtyController.text.trim()) ?? 10;

                        if (finalName.isNotEmpty && finalRef.isNotEmpty) {
                          final matchQuery = await _firestore
                              .collection('master_list')
                              .where('refNum', isEqualTo: finalRef)
                              .limit(1)
                              .get();

                          if (matchQuery.docs.isNotEmpty) {
                            final docId = matchQuery.docs.first.id;
                            final baseQty = matchQuery.docs.first['quantity'] ?? 0;
                            int updatedTotal = isAdding ? (baseQty + targetDelta) : (baseQty - targetDelta);
                            if (updatedTotal < 0) updatedTotal = 0;

                            String statusStr = "In stock";
                            if (updatedTotal == 0) {
                              statusStr = "Out of Stock";
                            } else if (updatedTotal < targetMin) statusStr = "Low Stock";

                            await _firestore.collection('master_list').doc(docId).update({
                              'name': finalName,
                              'category': finalCat,
                              'quantity': updatedTotal,
                              'minLimit': 'Min: $targetMin',
                              'status': statusStr,
                              'isIncrement': isAdding,
                            });

                            await _firestore.collection('activities').add({
                              'itemName': finalName,
                              'refNumber': finalRef,
                              'qty': isAdding ? targetDelta.abs() : -targetDelta.abs(),
                              'status': isAdding ? 'added' : 'shipped',
                              'timestamp': FieldValue.serverTimestamp(),
                              'dateString': _generateActivityDateString(),
                              'createdBy': widget.userCode,
                            });
                          }

                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        minimumSize: const Size(140, 48),
                        maximumSize: const Size(200, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                      child: Text(
                        isAdding ? "Add Item" : "Ship Item",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScanConfirmationModal({
    required bool isAdding,
    required String scannedName,
    required String scannedRef,
    required String scannedCategory,
    required int currentQty,
    required int minLimit,
  }) {
    final nameController = TextEditingController(text: scannedName);
    final refController = TextEditingController(text: scannedRef);
    final categoryController = TextEditingController(text: scannedCategory);
    final qtyChangeController = TextEditingController(text: "1");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Confirm Scanned Item",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 24),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Verify if the scanned product metadata below matches your physical package.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade100),
                ),
                const SizedBox(height: 16),

                _buildModalLabel("Item Name"),
                const SizedBox(height: 6),
                _buildModalTextField(controller: nameController, hint: "", isReadOnly: true),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel("Reference Number"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: refController, hint: "", isReadOnly: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel("Category"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: categoryController, hint: "", isReadOnly: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel(isAdding ? "Quantity to Add *" : "Quantity to Ship *"),
                          const SizedBox(height: 6),
                          _buildModalTextField(controller: qtyChangeController, hint: "", isNumeric: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModalLabel("Current System Stock"),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              "$currentQty units",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Incorrect / Rescan", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final int deltaQty = int.tryParse(qtyChangeController.text.trim()) ?? 1;

                        final querySnapshot = await _firestore
                            .collection('master_list')
                            .where('refNum', isEqualTo: scannedRef)
                            .limit(1)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          final docId = querySnapshot.docs.first.id;
                          int newQty = isAdding ? (currentQty + deltaQty) : (currentQty - deltaQty);
                          if (newQty < 0) newQty = 0;

                          String status = "In stock";
                          if (newQty == 0) {
                            status = "Out of Stock";
                          } else if (newQty < minLimit) status = "Low Stock";

                          await _firestore.collection('master_list').doc(docId).update({
                            'quantity': newQty,
                            'status': status,
                            'isIncrement': isAdding,
                          });

                          await _firestore.collection('activities').add({
                            'itemName': scannedName,
                            'refNumber': scannedRef,
                            'qty': isAdding ? deltaQty.abs() : -deltaQty.abs(),
                            'status': isAdding ? 'added' : 'shipped',
                            'timestamp': FieldValue.serverTimestamp(),
                            'dateString': _generateActivityDateString(),
                            'createdBy': widget.userCode,
                          });
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Confirm", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        minimumSize: const Size(140, 48),
                        maximumSize: const Size(200, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualInputModal({required bool isAdding}) {
    final nameController = TextEditingController();
    final refController = TextEditingController();
    final categoryController = TextEditingController();
    final qtyController = TextEditingController();
    final minQtyController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('master_list').snapshots(),
            builder: (context, snapshot) {
              List<Map<String, dynamic>> masterPool = [];
              if (snapshot.hasData) {
                masterPool = snapshot.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return {
                    'name': d['name'] ?? '',
                    'refNum': d['refNum'] ?? '',
                    'category': d['category'] ?? '',
                    'minLimit': d['minLimit'] ?? 'Min: 10',
                    'quantity': d['quantity'] ?? 0,
                  };
                }).toList();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAdding ? "Manual Input (Add)" : "Manual Input (Ship)",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildModalLabel("Reference Number"),
                    const SizedBox(height: 6),

                    RawAutocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) => option['refNum'],
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return masterPool.where((option) {
                          final query = textEditingValue.text.toLowerCase();
                          return option['refNum'].toLowerCase().contains(query) ||
                              option['name'].toLowerCase().contains(query);
                        });
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.white, // FIX: Define surface color here so ink layers can render
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 320,
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                // FIX: Removed 'color: Colors.white' from here
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option['refNum'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text("${option['name']} (${option['category']})"),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                        textController.addListener(() {
                          refController.text = textController.text;
                        });
                        return TextFormField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Type reference code or item name...",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: const Icon(Icons.search, size: 20),
                          ),
                        );
                      },
                      onSelected: (option) {
                        refController.text = option['refNum'];
                        nameController.text = option['name'];
                        categoryController.text = option['category'];

                        String rawMin = option['minLimit'] ?? "10";
                        minQtyController.text = rawMin.replaceAll(RegExp(r'[^0-9]'), '');
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildModalLabel("Item Name *"),
                    const SizedBox(height: 6),
                    _buildModalTextField(controller: nameController, hint: "Auto-populated name"),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalLabel("Category *"),
                              const SizedBox(height: 6),
                              _buildModalTextField(controller: categoryController, hint: "Auto-populated category"),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalLabel("Quantity *"),
                              const SizedBox(height: 6),
                              _buildModalTextField(controller: qtyController, hint: "0", isNumeric: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalLabel("Min Quantity *"),
                              const SizedBox(height: 6),
                              _buildModalTextField(controller: minQtyController, hint: "10", isNumeric: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final String name = nameController.text.trim();
                            final String ref = refController.text.trim();
                            final int qty = int.tryParse(qtyController.text.trim()) ?? 0;
                            final int minQty = int.tryParse(minQtyController.text.trim()) ?? 10;

                            if (name.isNotEmpty && ref.isNotEmpty && qty >= 0) {
                              final querySnapshot = await _firestore
                                  .collection('master_list')
                                  .where('refNum', isEqualTo: ref)
                                  .limit(1)
                                  .get();

                              if (querySnapshot.docs.isNotEmpty) {
                                final docId = querySnapshot.docs.first.id;
                                final currentQty = querySnapshot.docs.first['quantity'] ?? 0;
                                int newQty = isAdding ? (currentQty + qty) : (currentQty - qty);
                                if (newQty < 0) newQty = 0;

                                String status = "In stock";
                                if (newQty == 0) {
                                  status = "Out of Stock";
                                } else if (newQty < minQty) status = "Low Stock";

                                await _firestore.collection('master_list').doc(docId).update({
                                  'quantity': newQty,
                                  'status': status,
                                  'isIncrement': isAdding,
                                });

                                await _firestore.collection('activities').add({
                                  'itemName': querySnapshot.docs.first['name'] ?? name,
                                  'refNumber': ref,
                                  'qty': isAdding ? qty.abs() : -qty.abs(),
                                  'status': isAdding ? 'added' : 'shipped',
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'dateString': _generateActivityDateString(),
                                  'createdBy': widget.userCode,
                                });

                                if (context.mounted) Navigator.pop(context);
                              } else {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Row(
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text("Unregistered Item"),
                                        ],
                                      ),
                                      content: Text("The reference number '$ref' does not exist in the master record list profiles. Please add the profile inside the master spreadsheet first."),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("OK", style: TextStyle(color: navNavy)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(isAdding ? Icons.add : Icons.remove, size: 18),
                          label: Text(isAdding ? "Add Item" : "Ship Item", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleInventoryActionDispatch({required bool isAdding}) {
    setState(() {
      _isScannerAddingMode = isAdding;
    });

    if (_selectedShortcutIndex == 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isAdding ? Icons.add_circle_outline : Icons.remove_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                isAdding ? "System Ready: Scan item barcode to ADD to stock" : "System Ready: Scan item barcode to SHIP/SUBTRACT from stock",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      _showManualInputModal(isAdding: isAdding);
    }
  }

  Widget _buildModalLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumeric = false,
    bool isReadOnly = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: isReadOnly ? Colors.grey.shade700 : Colors.black, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          isDense: true,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _globalScannerFocusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          final String? character = event.character;

          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {

            if (_scannedBufferContext.trim().isNotEmpty) {
              String cleanBarcode = _scannedBufferContext.trim();
              _scannedBufferContext = "";

              _handleHardwareScanInput(cleanBarcode, isAdding: _isScannerAddingMode);
            }
          } else if (character != null) {
            _scannedBufferContext += character;
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          if (!_globalScannerFocusNode.hasFocus) {
            _globalScannerFocusNode.requestFocus();
          }
        },
        child: Container(
          color: const Color(0xFFF3F4F6),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Track your packages", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 4),
              Text("Manage your packages here", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 20),

              Row(
                children: [
                  _buildShortcutCard(
                    index: 0,
                    title: "SCAN BARCODE",
                    subtitle: "Log automatically",
                    icon: Icons.qr_code_scanner_outlined,
                    activeBgColor: const Color(0xFFE8F5E9),
                    activeBorderColor: const Color(0xFFA5D6A7),
                    activeIconColor: const Color(0xFF2E7D32),
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _buildShortcutCard(
                    index: 1,
                    title: "MANUAL INPUT",
                    subtitle: "Encode manually",
                    icon: Icons.edit_note_outlined,
                    activeBgColor: const Color(0xFFFEF3C7),
                    activeBorderColor: const Color(0xFFFDE68A),
                    activeIconColor: const Color(0xFFD97706),
                    onTap: () => _showManualInputModal(isAdding: true),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Inventory Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text("Manage your inventory items", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),

                  const Spacer(),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _handleInventoryActionDispatch(isAdding: true),
                        icon: Icon(
                          Icons.add,
                          size: 18,
                          color: (_selectedShortcutIndex == 0 && _isScannerAddingMode) ? Colors.white : const Color(0xFF2E7D32),
                        ),
                        label: const Text("Add Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_selectedShortcutIndex == 0 && _isScannerAddingMode)
                              ? const Color(0xFF2E7D32)
                              : Colors.white,
                          foregroundColor: (_selectedShortcutIndex == 0 && _isScannerAddingMode)
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                          side: BorderSide(
                            color: (_selectedShortcutIndex == 0 && _isScannerAddingMode) ? Colors.transparent : const Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: (_selectedShortcutIndex == 0 && _isScannerAddingMode) ? 2 : 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _handleInventoryActionDispatch(isAdding: false),
                        icon: Icon(
                          Icons.remove,
                          size: 18,
                          color: (_selectedShortcutIndex == 0 && !_isScannerAddingMode) ? Colors.white : const Color(0xFFEF4444),
                        ),
                        label: const Text("Shipped Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_selectedShortcutIndex == 0 && !_isScannerAddingMode)
                              ? const Color(0xFFEF4444)
                              : Colors.white,
                          foregroundColor: (_selectedShortcutIndex == 0 && !_isScannerAddingMode)
                              ? Colors.white
                              : const Color(0xFFEF4444),
                          side: BorderSide(
                            color: (_selectedShortcutIndex == 0 && !_isScannerAddingMode) ? Colors.transparent : const Color(0xFFEF4444),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: (_selectedShortcutIndex == 0 && !_isScannerAddingMode) ? 2 : 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                          hintText: "Search name / ref number",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
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

              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xFFEFEFF4),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Ref Num", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                              SizedBox(width: 32),
                            ],
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore.collection('master_list').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) return const Center(child: Text("Error fetching records"));
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              if (snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text("No items currently tracked in database."));
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

                                  final Object? rawData = doc.data();
                                  if (rawData == null || rawData is! Map<String, dynamic>) {
                                    return const SizedBox.shrink();
                                  }
                                  final Map<String, dynamic> data = rawData;

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

  Widget _buildShortcutCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeBgColor,
    required Color activeBorderColor,
    required Color activeIconColor,
    required VoidCallback onTap,
  }) {
    bool isSelected = _selectedShortcutIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedShortcutIndex = isSelected ? -1 : index;
          });
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? activeBorderColor : Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100)),
                child: Icon(icon, color: isSelected ? activeIconColor : Colors.grey.shade500, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Icon(prefixIcon, color: Colors.grey.shade500, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500, size: 20),
                items: items.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 13)));
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(isIncrement ? Icons.add : Icons.remove, color: isIncrement ? const Color(0xFF2E7D32) : const Color(0xFFC62828), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 14, color: Colors.black), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(refNum, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(category, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 4),
                Expanded(child: Text(minLimit, style: TextStyle(color: Colors.grey.shade400, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_note, color: Color(0xFF0C245E), size: 22), onPressed: () {})
        ],
      ),
    );
  }
}