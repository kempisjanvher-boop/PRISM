import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  static const Color navNavy = Color(0xFF0C245E);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'Employee';

  @override
  void initState() {
    super.initState();
    _migrateExistingUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _generateUniqueUserCode(String role) async {
    String prefix = role == 'Admin' ? '69' : '67';
    String startCode = '${prefix}00001';
    String endCode = '${prefix}99999';

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('userCode', isGreaterThanOrEqualTo: startCode)
        .where('userCode', isLessThanOrEqualTo: endCode)
        .get();

    int maxNumber = 0;
    for (var doc in snapshot.docs) {
      String userCode = doc['userCode'] as String;
      int number = int.tryParse(userCode.substring(2)) ?? 0;
      if (number > maxNumber) maxNumber = number;
    }

    return '$prefix${(maxNumber + 1).toString().padLeft(5, '0')}';
  }

  Future<void> _migrateExistingUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String role = data['role'] ?? 'Employee';
      String? existingUserCode = data['userCode'];

      if (existingUserCode == null || existingUserCode.isEmpty) {
        String newUserCode = await _generateUniqueUserCode(role);
        await _firestore.collection('users').doc(doc.id).update({
          'userCode': newUserCode,
          'userSubCode': '000000',
        });
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const ['Admin', 'Employee'].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (value) => setDialogState(() => _selectedRole = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _emailController.clear();
                    _passwordController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                      try {
                        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );

                        String userCode = await _generateUniqueUserCode(_selectedRole);

                        await _firestore.collection('users').doc(userCredential.user!.uid).set({
                          'email': _emailController.text.trim(),
                          'role': _selectedRole, // Saves as 'Admin' or 'Employee'
                          'userCode': userCode,
                          'userSubCode': '000000',
                          'status': 'Active',
                          'lastLogin': 'Never',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        _emailController.clear();
                        _passwordController.clear();
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating user: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: navNavy),
                  child: const Text('Add User', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        int totalUsers = 0;
        int adminCount = 0;
        int activeCount = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalUsers = docs.length;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            // FIXED: Changed metric validator from 'Administrator' to match your 'Admin' string dropdown selection
            if (data['role'] == 'Admin' || data['role'] == 'Administrator') adminCount++;
            if (data['status'] == 'Active') activeCount++;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("User Management", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Manage and monitor all user accounts", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 36),

              // Summary Cards Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.people_outline, color: Color(0xFF0369A1), size: 32),
                          ),
                          const SizedBox(height: 24),
                          Text(totalUsers.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Total Users", style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
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
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.admin_panel_settings, color: Color(0xFFD97706), size: 32),
                          ),
                          const SizedBox(height: 24),
                          Text(adminCount.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Administrator", style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
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
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 32),
                          ),
                          const SizedBox(height: 24),
                          Text(activeCount.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Active Users", style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Users Table Component Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("All Users", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showAddUserDialog,
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text("Add User", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: const Color(0xFFEFEFF4),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 3, child: Text("Email", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          Expanded(flex: 2, child: Text("Last Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                          SizedBox(width: 80),
                        ],
                      ),
                    ),
                    if (!snapshot.hasData)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(navNavy))),
                      )
                    else if (snapshot.data!.docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text("No users found", style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        padding: EdgeInsets.zero,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          String status = data['status'] ?? 'Active';
                          Color statusBg = const Color(0xFFDCFCE7);
                          Color statusText = const Color(0xFF16A34A);

                          if (status != "Active") {
                            statusBg = const Color(0xFFFEE2E2);
                            statusText = const Color(0xFFEF4444);
                          }

                          // FIXED / TYPE-SAFE ASSIGNMENTS: Protects row fields from blowing up if Timestamp objects pass into text allocations
                          String lastLoginString = '';
                          dynamic rawLogin = data['lastLogin'];
                          if (rawLogin is Timestamp) {
                            DateTime dt = rawLogin.toDate();
                            lastLoginString = "${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}-${dt.year}";
                          } else {
                            lastLoginString = rawLogin?.toString() ?? 'Never';
                          }

                          return _buildUserRow(
                            name: data['name'] ?? data['email']?.toString().split('@')[0] ?? 'N/A',
                            email: data['email'] ?? 'N/A',
                            role: data['role'] ?? 'Employee',
                            lastLogin: lastLoginString,
                            statusText: status,
                            statusColor: statusBg,
                            textColor: statusText,
                            docId: doc.id,
                            userData: data,
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

  Widget _buildUserRow({
    required String name,
    required String email,
    required String role,
    required String lastLogin,
    required String statusText,
    required Color statusColor,
    required Color textColor,
    required String docId,
    required Map<String, dynamic> userData,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(name, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
          ),
          Expanded(flex: 3, child: Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 15))),
          Expanded(flex: 2, child: Text(role, style: TextStyle(color: Colors.grey.shade600, fontSize: 15))),
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
          Expanded(flex: 2, child: Text(lastLogin, style: TextStyle(color: Colors.grey.shade600, fontSize: 15))),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}