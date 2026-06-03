// ============================================================
// profile_page.dart — Customer Profile / Account Settings Screen
// ============================================================
// Lets the logged-in customer view and update their own account.
//
// Editable fields:
//   • Full name, phone number.
//
// Read-only fields:
//   • Username (primary key — cannot be changed).
//   • Email address (locked to prevent account-takeover; only
//     an admin can update it via the admin panel).
//
// Password change (separate section at the bottom):
//   • User must supply their correct Current Password.
//   • Then enter and confirm a New Password (min 8 chars).
//   • If the new password fields are left blank the password
//     is not changed — only the profile fields are saved.
//   • On success an email confirmation is sent to the user.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

/// Account settings screen for the logged-in customer.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Form state ────────────────────────────────────────────────

  // Separate keys so each card validates independently.
  final _profileFormKey  = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // Profile info controllers (email is display-only — no controller needed for saving).
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();

  // Password-change controllers — intentionally start empty.
  final _currentPwController  = TextEditingController();
  final _newPwController      = TextEditingController();
  final _confirmPwController  = TextEditingController();

  // Loaded once and never changed from this screen.
  String _username     = '';
  String _email        = '';
  String _storedName   = '';

  bool _isLoading             = true;
  bool _isSaving              = false;

  // Individual visibility toggles for the three password fields.
  bool _currentPwVisible = false;
  bool _newPwVisible     = false;
  bool _confirmPwVisible = false;

  final _emailService = EmailService();

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────

  /// Fetches the user record from the database and pre-fills editable fields.
  /// The password field is intentionally left blank for security.
  Future<void> _loadUserProfile() async {
    final prefs    = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';

    if (username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(username);
      if (user != null) {
        setState(() {
          _username   = username;
          _email      = user['email'] ?? '';
          _storedName = user['name'] ?? '';
          _nameController.text  = _storedName;
          _phoneController.text = user['phone'] ?? '';
          // Password field is deliberately left empty —
          // the user must type their current password to change it.
        });
      }
    }
    setState(() => _isLoading = false);
  }

  // ── Save handlers ─────────────────────────────────────────────

  /// Saves name + phone changes.  Does NOT touch email or password.
  Future<void> _saveProfileInfo() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedUser = {
      'username': _username,
      'name':     _nameController.text.trim(),
      'email':    _email,          // Keep the original — email cannot be changed here.
      'phone':    _phoneController.text.trim(),
    };

    await DatabaseHelper.instance.updateUser(updatedUser);
    setState(() {
      _storedName = _nameController.text.trim();
      _isSaving   = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Validates the current password, applies the new one, and sends
  /// a confirmation email.
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    // Fetch the live record to get the stored password hash/plain text.
    final user = await DatabaseHelper.instance.getUserByUsername(_username);
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    // Verify that the current password the user typed matches what is in the DB.
    if (_currentPwController.text != user['password']) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Current password is incorrect.'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Persist the new password.
    await DatabaseHelper.instance.updateUserPassword(_username, _newPwController.text);

    // Send a "password changed" confirmation email.
    final now       = DateTime.now();
    final changedAt = DateFormat('d MMMM yyyy, HH:mm').format(now);
    await _emailService.sendGoogleEmail(
      recipientEmails: _email,
      subject: 'Your Password Has Been Changed — Ali Grandson Spare Parts',
      htmlBody: await EmailTemplates.passwordChanged(_storedName, changedAt),
    );

    // Clear the password fields after a successful change.
    _currentPwController.clear();
    _newPwController.clear();
    _confirmPwController.clear();

    setState(() => _isSaving = false);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully! A confirmation email has been sent.'),
        backgroundColor: kSuccessColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('MY PROFILE'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // ── Profile info card ──────────────────────
                  _buildSectionLabel('Profile Information'),
                  const SizedBox(height: 12),
                  _buildProfileInfoCard(),
                  const SizedBox(height: 16),
                  _isSaving
                      ? const CircularProgressIndicator(color: kPrimaryColor)
                      : ElevatedButton(
                          onPressed: _saveProfileInfo,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('SAVE PROFILE'),
                        ),

                  const SizedBox(height: 40),

                  // ── Change password card ───────────────────
                  _buildSectionLabel('Change Password'),
                  const SizedBox(height: 12),
                  _buildChangePasswordCard(),
                  const SizedBox(height: 16),
                  _isSaving
                      ? const SizedBox.shrink()
                      : ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: kSecondaryColor,
                          ),
                          child: const Text('UPDATE PASSWORD'),
                        ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────

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
            child: Icon(Icons.person_rounded, size: 60, color: kGreyMedium),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _username,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kSecondaryColor),
        ),
        const Text(
          'Active Member',
          style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Labelled section heading above each card.
  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: kSecondaryColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Card with editable name + phone, and a locked email row.
  Widget _buildProfileInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGreyLight),
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Full Name ──────────────────────────────────
            _buildFieldLabel('Full Name'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
            ),

            const SizedBox(height: 20),

            // ── Phone Number ───────────────────────────────
            _buildFieldLabel('Phone Number'),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Phone is required' : null,
            ),

            const SizedBox(height: 20),

            // ── Email (locked) ─────────────────────────────
            _buildFieldLabel('Email Address'),
            // Email is displayed in a styled read-only tile instead of a
            // TextFormField so there is no way to accidentally edit it.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: kGrey100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGreyLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 20, color: kGreyMedium),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _email,
                      style: const TextStyle(fontSize: 15, color: kTextSecondary),
                    ),
                  ),
                  const Icon(Icons.lock_outline, size: 18, color: kGreyMedium),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Email address cannot be changed. Contact an admin if needed.',
              style: TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Card with current-password verification + new password fields.
  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGreyLight),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Current Password ───────────────────────────
            _buildFieldLabel('Current Password'),
            TextFormField(
              controller: _currentPwController,
              obscureText: !_currentPwVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: 'Enter your current password',
                suffixIcon: IconButton(
                  icon: Icon(_currentPwVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _currentPwVisible = !_currentPwVisible),
                ),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Current password is required' : null,
            ),

            const SizedBox(height: 20),

            // ── New Password ───────────────────────────────
            _buildFieldLabel('New Password'),
            TextFormField(
              controller: _newPwController,
              obscureText: !_newPwVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                hintText: 'Minimum 8 characters',
                suffixIcon: IconButton(
                  icon: Icon(_newPwVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _newPwVisible = !_newPwVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'New password is required';
                if (value.length < 8) return 'Minimum 8 characters';
                if (value == _currentPwController.text) return 'New password must differ from current';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── Confirm New Password ───────────────────────
            _buildFieldLabel('Confirm New Password'),
            TextFormField(
              controller: _confirmPwController,
              obscureText: !_confirmPwVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                hintText: 'Re-enter new password',
                suffixIcon: IconButton(
                  icon: Icon(_confirmPwVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _confirmPwVisible = !_confirmPwVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your new password';
                if (value != _newPwController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor),
      ),
    );
  }
}
