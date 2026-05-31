// ============================================================
// view_user_page.dart — Admin: User Detail Screen
// ============================================================
// Shows the admin all information about a single customer and
// provides three admin actions:
//
//   1. EDIT ACCOUNT   — opens EditUserPage to change user details.
//   2. RESET PASSWORD — generates a 10-character random password,
//        updates it in the DB, and emails it to the user.
//   3. DELETE USER    — permanently removes the account after
//        showing a confirmation dialog.
//
// The user data map is passed in from ManageUsersPage and contains
// username, name, email, phone, and date of birth.
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/features/profile/presentation/pages/edit_user_page.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

/// Admin screen showing details of a single customer account.
class ViewUserPage extends StatefulWidget {
  /// The customer's data map passed from the user list screen.
  final Map<String, dynamic> user;

  const ViewUserPage({super.key, required this.user});

  @override
  State<ViewUserPage> createState() => _ViewUserPageState();
}

class _ViewUserPageState extends State<ViewUserPage> {
  final EmailService _emailService = EmailService();
  bool _isResetting = false;

  String _generateRandomPassword(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _resetUserPassword() async {
    setState(() => _isResetting = true);
    
    final newPassword = _generateRandomPassword(10);
    final username = widget.user['username'];
    final email = widget.user['email'];
    final name = widget.user['name'] ?? username;

    try {
      // 1. Update Password in Database
      await DatabaseHelper.instance.updateUserPassword(username, newPassword);

      // 2. Send Email
      if (email != null && email.isNotEmpty) {
        final result = await _emailService.sendGoogleEmail(
          recipientEmails: email,
          subject: 'Your Password Has Been Reset - Ali Grandson Spare Parts',
          htmlBody: EmailTemplates.passwordReset(name, newPassword),
        );

        if (result['success']) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully and email sent to user.'),
              backgroundColor: kSuccessColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset in DB, but email failed: ${result['message']}'),
              backgroundColor: kWarningColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated in DB, but no email address found for user.'),
            backgroundColor: kWarningColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting password: $e'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('USER DETAILS'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                _buildDetailsCard(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
          if (_isResetting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kPrimaryColor, width: 2),
          ),
          child: const CircleAvatar(
            radius: 50,
            backgroundColor: kGreyLight,
            child: Icon(Icons.person_rounded, size: 60, color: kPrimaryColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.user['name'] ?? 'N/A',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kSecondaryColor),
        ),
        Text(
          '@${widget.user['username']}',
          style: const TextStyle(color: kTextSecondary, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGreyLight),
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.email_outlined, 'Email Address', widget.user['email'] ?? 'N/A'),
          const Divider(height: 32),
          _buildDetailItem(Icons.phone_outlined, 'Phone Number', widget.user['phone'] ?? 'N/A'),
          const Divider(height: 32),
          _buildDetailItem(Icons.calendar_month_outlined, 'Date of Birth', widget.user['dob'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kPrimaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kSecondaryColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditUserPage(user: widget.user)),
            );
          },
          icon: const Icon(Icons.edit_rounded, size: 20),
          label: const Text('EDIT ACCOUNT'),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isResetting ? null : () => _showResetConfirmationDialog(),
          icon: const Icon(Icons.lock_reset_rounded, size: 20),
          label: const Text('RESET PASSWORD'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: kAccentColor),
            foregroundColor: kAccentColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => _showDeleteConfirmationDialog(context, widget.user['username']),
          icon: const Icon(Icons.delete_forever_rounded, color: kErrorColor),
          label: const Text('PERMANENTLY REMOVE USER', style: TextStyle(color: kErrorColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will generate a random password and send it to the user\'s email. The user will be able to log in with the new password.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetUserPassword();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kAccentColor),
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, color: kErrorColor)),
        content: const Text('This will permanently delete the user and all their data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: kTextSecondary))),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteUser(username);
              if (!mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User removed successfully'), backgroundColor: kSecondaryColor, behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor, minimumSize: const Size(100, 40)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
