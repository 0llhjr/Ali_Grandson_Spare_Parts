// ============================================================
// manage_users_page.dart — Admin: User Accounts List Screen
// ============================================================
// Shows the admin a list of all registered customer accounts.
// A summary header shows the total count.
// Tapping a user card opens ViewUserPage where the admin can
// edit the account, reset the password, or delete the user.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'view_user_page.dart';

/// Admin screen listing all registered customer accounts.
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await DatabaseHelper.instance.getUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('USER ACCOUNTS'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderSummary(),
                Expanded(
                  child: _users.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) => _buildUserCard(_users[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: kSurfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_users.length} Registered Users',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kSecondaryColor),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage customer profiles and account access',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: kGreyMedium.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No users found', style: TextStyle(color: kTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kGreyLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kPrimaryColor.withOpacity(0.1),
          child: Text(
            (user['name'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['name'] ?? 'No Name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor),
        ),
        subtitle: Text(
          user['email'] ?? 'No Email',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: kTextSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreyMedium),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewUserPage(user: user)),
          ).then((_) => _loadUsers());
        },
      ),
    );
  }
}
