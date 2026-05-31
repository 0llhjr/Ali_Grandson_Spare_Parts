// ============================================================
// edit_user_page.dart — Admin: Edit Customer Account Screen
// ============================================================
// Allows the admin to modify a customer's profile fields:
//   name, email, phone, and date of birth.
//
// The username field is displayed as read-only because it is
// the primary key and cannot be changed without cascading issues.
//
// After saving, two Navigator.pop() calls are needed:
//   1st pop — closes this edit page.
//   2nd pop — closes the ViewUserPage so the list refreshes.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Admin form screen for modifying an existing customer's account details.
class EditUserPage extends StatefulWidget {
  /// The customer's current data map used to pre-fill the form fields.
  final Map<String, dynamic> user;

  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user['username'] ?? '');
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _dobController = TextEditingController(text: widget.user['dob'] ?? '');
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      final updatedUser = {
        'username': _usernameController.text,
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dob': _dobController.text,
      };
      await DatabaseHelper.instance.updateUser(updatedUser);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details updated successfully'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Close the edit page
      Navigator.pop(context); // Go back to the user details to refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('EDIT USER PROFILE'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildFormFields(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateUser,
                style: ElevatedButton.styleFrom(
                  shadowColor: kPrimaryColor.withOpacity(0.3),
                  elevation: 8,
                ),
                child: const Text('UPDATE INFORMATION'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: kGreyMedium),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: kTextSecondary,
                ),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: kGreyLight,
            child: Icon(Icons.manage_accounts_outlined, size: 40, color: kPrimaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user['username'] ?? 'User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kSecondaryColor),
          ),
          const Text('Administrative Modification', style: TextStyle(color: kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kGreyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Account Username (Read-only)'),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline, size: 20)),
            readOnly: true,
            enabled: false,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Full Name'),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline, size: 20)),
            validator: (value) => value!.isEmpty ? 'Enter name' : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Email Address'),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined, size: 20)),
            validator: (value) => value!.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Phone Number'),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, size: 20)),
            keyboardType: TextInputType.phone,
            validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Date of Birth'),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_month_outlined, size: 20)),
            readOnly: true,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _dobController.text = picked.toString().split(' ')[0]);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSecondaryColor),
      ),
    );
  }
}
