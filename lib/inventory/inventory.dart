import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrismInventoryPage extends StatefulWidget {
  final String userCode;

  const PrismInventoryPage({
    Key? key,
    required this.userCode,
  }) : super(key: key);

  @override
  State<PrismInventoryPage> createState() => _PrismInventoryPageState();
}

class _PrismInventoryPageState extends State<PrismInventoryPage> {
  static const Color navNavy = Color(0xFF0C245E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track active shortcut mode: -1 = None, 0 = Scan Barcode, 1 = Manual Input
  int _selectedShortcutIndex = -1;


  // ==========================================
  // STEP 1: BARCODE SCANNING MODAL VIEWPORT
  // ==========================================
  void _showBarcodeScanningModal({required bool isAdding}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAdding ? "Scan Barcode to Add" : "Scan Barcode to Ship",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Scanning Viewfinder Box Frame
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Opacity(
                      opacity: 0.3,
                      child: Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white),
                    ),
                    Container(
                      width: 220,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Positioned(
                      child: Container(
                        width: 210,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(color: Colors.red, blurRadius: 8, spreadRadius: 2),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 16,
                      child: Text(
                        "Align item barcode within the frame line box",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Simulated Quick Scan Action Trigger
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Close the camera view scanner window first
                    Navigator.pop(context);

                    // Launch the quick processing confirmation action toast frame box
                    _showScanActionConfirmationModal(isAdding: isAdding);
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text("Simulate Successful Barcode Detect", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // STEP 2: VERIFICATION / CONFIRMATION MODAL
  // ==========================================
  void _showScanActionConfirmationModal({required bool isAdding}) async {
    // 1. Define simulated barcode value
    String mockBarcodeRef = "1234567890123";

    // Default fallback values if document doesn't exist in Firestore yet
    String matchedName = "Package01";
    String matchedCategory = "ABC";
    int currentQty = 0;
    int minLimit = 10;

    // 2. Query Firestore to fetch real matching record information if available
    final querySnapshot = await _firestore
        .collection('inventory')
        .where('refNum', isEqualTo: mockBarcodeRef)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final docData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      matchedName = docData['name'] ?? matchedName;
      matchedCategory = docData['category'] ?? matchedCategory;
      currentQty = docData['quantity'] ?? 0;

      // Parse out number out of "Min: 10" string if saved that way
      String rawMin = docData['minLimit'] ?? "Min: 10";
      minLimit = int.tryParse(rawMin.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10;
    }

    // 3. Set up pre-filled controllers to mimic the exact layout view image metadata
    final nameController = TextEditingController(text: matchedName);
    final refController = TextEditingController(text: mockBarcodeRef);
    final categoryController = TextEditingController(text: matchedCategory);
    final qtyController = TextEditingController(text: isAdding ? "45" : "1"); // Pre-fill sample or default step delta modifications
    final minQtyController = TextEditingController(text: minLimit.toString());

    if (!mounted) return;

    // 4. Fire the presentation box matching your exact user interface images
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 650, // High-density exact size matching manual input
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title block with Close X mark icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAdding ? "Add New Item" : "Ship Item Details",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 28, color: Colors.black87),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Full Width Item Name
              _buildModalLabel("Item Name *"),
              const SizedBox(height: 8),
              _buildModalTextField(controller: nameController, hint: ""),
              const SizedBox(height: 20),

              // Reference Number & Category Side-By-Side Row Layout Set pieces
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Reference Number *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: refController, hint: ""),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Category*"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: categoryController, hint: ""),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quantities Side-by-Side Row Layout Set pieces
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel(isAdding ? "Quantity *" : "Quantity Shipped *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: qtyController, hint: "", isNumeric: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Min Quantity *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: minQtyController, hint: "", isNumeric: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Action buttons footer matches exact card designs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel dismiss action configuration
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  // Primary Write Action Dispatch Button
                  ElevatedButton(
                    onPressed: () async {
                      final String finalName = nameController.text.trim();
                      final String finalRef = refController.text.trim();
                      final String finalCat = categoryController.text.trim();
                      final int targetDelta = int.tryParse(qtyController.text.trim()) ?? 0;
                      final int targetMin = int.tryParse(minQtyController.text.trim()) ?? 10;

                      if (finalName.isNotEmpty && finalRef.isNotEmpty) {
                        // Re-fetch document match target to execute precise quantity mutation
                        final matchQuery = await _firestore
                            .collection('inventory')
                            .where('refNum', isEqualTo: finalRef)
                            .limit(1)
                            .get();

                        if (matchQuery.docs.isNotEmpty) {
                          final docId = matchQuery.docs.first.id;
                          final baseQty = matchQuery.docs.first['quantity'] ?? 0;
                          int updatedTotal = isAdding ? (baseQty + targetDelta) : (baseQty - targetDelta);
                          if (updatedTotal < 0) updatedTotal = 0;

                          String statusStr = "In stock";
                          if (updatedTotal == 0) statusStr = "Out of Stock";
                          else if (updatedTotal < targetMin) statusStr = "Low Stock";

                          await _firestore.collection('inventory').doc(docId).update({
                            'name': finalName,
                            'category': finalCat,
                            'quantity': updatedTotal,
                            'minLimit': 'Min: $targetMin',
                            'status': statusStr,
                            'isIncrement': isAdding,
                          });
                        } else if (isAdding) {
                          String statusStr = "In stock";
                          if (targetDelta == 0) statusStr = "Out of Stock";
                          else if (targetDelta < targetMin) statusStr = "Low Stock";

                          await _firestore.collection('inventory').add({
                            'name': finalName,
                            'refNum': finalRef,
                            'category': finalCat,
                            'quantity': targetDelta,
                            'minLimit': 'Min: $targetMin',
                            'status': statusStr,
                            'isIncrement': true,
                          });
                        }

                        // Write transaction ledger audit document track entry
                        await _firestore.collection('activities').add({
                          'itemName': finalName,
                          'refNumber': finalRef,
                          'qty': targetDelta,
                          'timestamp': FieldValue.serverTimestamp(),
                          'dateString': "06-22-2026",
                          'createdBy': widget.userCode,
                        });

                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: Text(
                      isAdding ? "Add Item" : "Ship Item",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
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
    final qtyChangeController = TextEditingController(text: "1"); // Default configuration modifier value

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Confirm Scanned Item",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 28),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Verify if the scanned product metadata below matches your physical package.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              _buildModalLabel("Item Name"),
              const SizedBox(height: 8),
              _buildModalTextField(controller: nameController, hint: "", isReadOnly: true),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Reference Number"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: refController, hint: "", isReadOnly: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Category"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: categoryController, hint: "", isReadOnly: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel(isAdding ? "Quantity to Add *" : "Quantity to Ship *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: qtyChangeController, hint: "", isNumeric: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Current System Stock"),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            "$currentQty units available",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Incorrect / Rescan", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final int deltaQty = int.tryParse(qtyChangeController.text.trim()) ?? 1;

                      final querySnapshot = await _firestore
                          .collection('inventory')
                          .where('refNum', isEqualTo: scannedRef)
                          .limit(1)
                          .get();

                      if (querySnapshot.docs.isNotEmpty) {
                        final docId = querySnapshot.docs.first.id;
                        int newQty = isAdding ? (currentQty + deltaQty) : (currentQty - deltaQty);
                        if (newQty < 0) newQty = 0;

                        String status = "In stock";
                        if (newQty == 0) status = "Out of Stock";
                        else if (newQty < minLimit) status = "Low Stock";

                        await _firestore.collection('inventory').doc(docId).update({
                          'quantity': newQty,
                          'status': status,
                          'isIncrement': isAdding,
                        });
                      } else if (isAdding) {
                        // Create item if it doesn't exist yet
                        String status = deltaQty == 0 ? "Out of Stock" : (deltaQty < minLimit ? "Low Stock" : "In stock");

                        await _firestore.collection('inventory').add({
                          'name': scannedName,
                          'refNum': scannedRef,
                          'category': scannedCategory,
                          'quantity': deltaQty,
                          'minLimit': 'Min: $minLimit',
                          'status': status,
                          'isIncrement': true,
                        });
                      }

                      // Write activity history entry snapshot record
                      await _firestore.collection('activities').add({
                        'itemName': scannedName,
                        'refNumber': scannedRef,
                        'qty': deltaQty,
                        'timestamp': FieldValue.serverTimestamp(),
                        'dateString': "06-22-2026",
                        'createdBy': widget.userCode,
                      });

                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text("Yes, Correct", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ORIGINAL MANUAL INPUT MODAL CONTAINER
  // ==========================================
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
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Manual Input", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 28))
                ],
              ),
              const SizedBox(height: 24),
              _buildModalLabel("Item Name *"),
              const SizedBox(height: 8),
              _buildModalTextField(controller: nameController, hint: ""),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Reference Number *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: refController, hint: ""),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Category *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: categoryController, hint: ""),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Quantity *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: qtyController, hint: "", isNumeric: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModalLabel("Min Quantity *"),
                        const SizedBox(height: 8),
                        _buildModalTextField(controller: minQtyController, hint: "", isNumeric: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final String name = nameController.text.trim();
                      final String ref = refController.text.trim();
                      final String category = categoryController.text.trim();
                      final int qty = int.tryParse(qtyController.text.trim()) ?? 0;
                      final int minQty = int.tryParse(minQtyController.text.trim()) ?? 10;

                      if (name.isNotEmpty && ref.isNotEmpty && qty >= 0) {
                        final querySnapshot = await _firestore
                            .collection('inventory')
                            .where('refNum', isEqualTo: ref)
                            .limit(1)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          final docId = querySnapshot.docs.first.id;
                          final currentQty = querySnapshot.docs.first['quantity'] ?? 0;
                          int newQty = isAdding ? (currentQty + qty) : (currentQty - qty);
                          if (newQty < 0) newQty = 0;

                          String status = "In stock";
                          if (newQty == 0) status = "Out of Stock";
                          else if (newQty < minQty) status = "Low Stock";

                          await _firestore.collection('inventory').doc(docId).update({
                            'quantity': newQty,
                            'status': status,
                            'isIncrement': isAdding,
                          });
                        } else if (isAdding) {
                          String status = "In stock";
                          if (qty == 0) status = "Out of Stock";
                          else if (qty < minQty) status = "Low Stock";

                          await _firestore.collection('inventory').add({
                            'name': name,
                            'refNum': ref,
                            'category': category,
                            'quantity': qty,
                            'minLimit': 'Min: $minQty',
                            'status': status,
                            'isIncrement': true,
                          });
                        }

                        await _firestore.collection('activities').add({
                          'itemName': name,
                          'refNumber': ref,
                          'qty': qty,
                          'timestamp': FieldValue.serverTimestamp(),
                          'dateString': "06-22-2026",
                          'createdBy': widget.userCode,
                        });

                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: Icon(isAdding ? Icons.add : Icons.remove, size: 20),
                    label: Text(isAdding ? "Add Item" : "Ship Item", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdding ? navNavy : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Routing gateway logic separating execution profiles based on panel states
  void _handleInventoryActionDispatch({required bool isAdding}) {
    if (_selectedShortcutIndex == 0) {
      // If SCAN BARCODE card is currently active highlights mode
      _showBarcodeScanningModal(isAdding: isAdding);
    } else {
      // Defaults or explicit Fallback to the standard text field form manual template framework look layout setup panel
      _showManualInputModal(isAdding: isAdding);
    }
  }

  Widget _buildModalLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumeric = false,
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: isReadOnly ? Colors.grey.shade700 : Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Track your packages", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 6),
          Text("Manage your packages here", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 28),

          Row(
            children: [
              _buildShortcutCard(
                index: 0,
                title: "SCAN BARCODE",
                subtitle: "Automatically log your packages",
                icon: Icons.qr_code_scanner_outlined,
                activeBgColor: const Color(0xFFE8F5E9),
                activeBorderColor: const Color(0xFFA5D6A7),
                activeIconColor: const Color(0xFF2E7D32),
                onTap: () {},
              ),
              const SizedBox(width: 24),
              _buildShortcutCard(
                index: 1,
                title: "MANUAL INPUT",
                subtitle: "Manually encode your packages",
                icon: Icons.edit_note_outlined,
                activeBgColor: const Color(0xFFFEF3C7),
                activeBorderColor: const Color(0xFFFDE68A),
                activeIconColor: const Color(0xFFD97706),
                onTap: () => _showManualInputModal(isAdding: true),
              ),
            ],
          ),
          const SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Inventory Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text("Manage your inventory items", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleInventoryActionDispatch(isAdding: true),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text("Add Item", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _handleInventoryActionDispatch(isAdding: false),
                    icon: const Icon(Icons.remove, size: 20),
                    label: const Text("Shipped Item", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(flex: 2, child: _buildFilterDropdown(prefixIcon: Icons.search, hintText: "Search by name or reference number")),
              const SizedBox(width: 16),
              Expanded(child: _buildFilterDropdown(prefixIcon: Icons.filter_alt_outlined, hintText: "All Categories")),
              const SizedBox(width: 16),
              Expanded(child: _buildFilterDropdown(prefixIcon: Icons.playlist_add_check, hintText: "All Status")),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFEFEFF4),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Ref Num", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('inventory').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Center(child: Text("Error fetching records"));
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          if (snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No items currently tracked in inventory system database setup."));
                          }

                          return ListView.separated(
                            itemCount: snapshot.data!.docs.length,
                            padding: EdgeInsets.zero,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              var doc = snapshot.data!.docs[index];
                              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                              String status = data['status'] ?? 'In stock';
                              Color statusBg = const Color(0xFFE8F5E9);
                              Color statusText = const Color(0xFF2E7D32);

                              if (status == "Low Stock") {
                                statusBg = const Color(0xFFFFF3E0);
                                statusText = const Color(0xFFEF6C00);
                              } else if (status == "Out of Stock") {
                                statusBg = const Color(0xFFFFEBEE);
                                statusText = const Color(0xFFC62828);
                              }

                              return _buildInventoryRow(
                                name: data['name'] ?? '',
                                refNum: data['refNum'] ?? '',
                                category: data['category'] ?? '',
                                qty: (data['quantity'] ?? 0).toString(),
                                minLimit: data['minLimit'] ?? 'Min: 10',
                                statusText: status,
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? activeBorderColor : Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100)),
                child: Icon(icon, color: isSelected ? activeIconColor : Colors.grey.shade500, size: 30),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({required IconData prefixIcon, required String hintText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        decoration: InputDecoration(icon: Icon(prefixIcon, color: Colors.grey.shade500), hintText: hintText, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15), border: InputBorder.none),
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
                Text(name, style: const TextStyle(fontSize: 16, color: Colors.black)),
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
          IconButton(icon: const Icon(Icons.edit_note, color: Color(0xFF0C245E)), onPressed: () {})
        ],
      ),
    );
  }
}