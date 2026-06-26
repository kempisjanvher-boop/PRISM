import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ScanHandlerScreen extends StatefulWidget {
  const ScanHandlerScreen({super.key});

  @override
  _ScanHandlerScreenState createState() => _ScanHandlerScreenState();
}

class _ScanHandlerScreenState extends State<ScanHandlerScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Keeps the focus on the text field automatically.
    // Physical hardware USB scanners act like clip-on keyboards; they type instantly into whatever is focused.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  // Generates a mock systematic reference number matching your framework's architecture
  String _generateReferenceNumber() {
    var random = Random();
    int num = random.nextInt(900000) + 100000;
    return "PRISM-$num";
  }

  Future<void> _handleInboundEntry(String barcode) async {
    if (barcode.trim().isEmpty) return;

    setState(() { _isProcessing = true; });

    try {
      // Direct Firestore push representing Validation & Inbound Routing logic
      await FirebaseFirestore.instance.collection('parcels').doc(barcode).set({
        'barcode_id': barcode,
        'reference_number': _generateReferenceNumber(),
        'status': 'Inbound',
        'timestamp_received': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Parcel $barcode Synchronized Successfully!"), backgroundColor: Colors.green),
      );

      _inputController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isProcessing = false; });
      // Re-focus immediately so the next barcode scan reads seamlessly
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inbound Entry Module")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              "Awaiting Scan Input...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Note: If your hardware scanner is unavailable, you can explicitly type the barcode manually via Fallback Keyboard Logic below.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _inputController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Scan Target / Manual Barcode Input",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.keyboard),
              ),
              onSubmitted: (value) {
                _handleInboundEntry(value);
              },
            ),
            SizedBox(height: 20),
            _isProcessing
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: () => _handleInboundEntry(_inputController.text),
              icon: Icon(Icons.cloud_upload),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text("Process Inbound Log", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}