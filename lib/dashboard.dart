import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_handler.dart';

class PrismMainDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PRISM - Live Inventory Synchronization"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: () {
              // Navigate to scanning / input module
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanHandlerScreen()),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Real-Time Synchronization: Listening directly to the Firestore collection
        stream: FirebaseFirestore.instance.collection('parcels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error loading data.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final parcels = snapshot.data!.docs;

          if (parcels.isEmpty) {
            return Center(child: Text('No parcels in the repository.'));
          }

          return ListView.builder(
            itemCount: parcels.length,
            itemBuilder: (context, index) {
              var parcel = parcels[index].data() as Map<String, dynamic>;
              String docId = parcels[index].id;
              bool isInbound = parcel['status'] == 'Inbound';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isInbound ? Icons.archive : Icons.unarchive,
                    color: isInbound ? Colors.amber : Colors.green,
                  ),
                  title: Text("Barcode: ${parcel['barcode_id']}"),
                  subtitle: Text("Ref: ${parcel['reference_number']} | Status: ${parcel['status']}"),
                  trailing: isInbound
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Handoff", style: TextStyle(color: Colors.white)),
                    onPressed: () => _showHandoffDialog(context, docId),
                  )
                      : Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Secure Physical Handoff (Retrieval Process)
  void _showHandoffDialog(BuildContext context, String docId) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Secure Physical Handoff"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "Recipient Name / Signature ID"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('parcels').doc(docId).update({
                  'status': 'Retrieved',
                  'retrieved_by_user': nameController.text,
                  'timestamp_retrieved': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: Text("Confirm Release"),
          )
        ],
      ),
    );
  }
}