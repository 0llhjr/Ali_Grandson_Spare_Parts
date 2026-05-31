// ============================================================
// profile_page.dart — Customer Profile / Account Settings Screen
// ============================================================
// Lets the logged-in customer view and update their own account:
//   • Full name, email address, phone number, and password.
//   • Email uniqueness is checked before saving to prevent
//     accidentally taking another user's email.
//   • After saving, the email stored in SharedPreferences is also
//     updated so the session remains consistent.
//
// The username is read-only (it is the primary key and cannot
// be changed by the user from this screen).
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Account settings screen for the logged-in customer.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _username = '';
  bool _isLoading = true;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username') ?? '';

    if (username.isNotEmpty) {
      final user = await DatabaseHelper.instance.getUserByUsername(username);
      if (user != null) {
        setState(() {
          _username = username;
          _nameController.text = user['name'] ?? '';
          _emailController.text = user['email'] ?? '';
          _phoneController.text = user['phone'] ?? '';
          _passwordController.text = user['password'] ?? '';
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;

      final isEmailTaken = await DatabaseHelper.instance.isEmailTaken(email, _username);
      if (isEmailTaken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email is already registered.'), backgroundColor: kErrorColor),
        );
        return;
      }

      final updatedUser = {
        'username': _username,
        'name': _nameController.text,
        'email': email,
        'phone': _phoneController.text,
        'password': _passwordController.text,
      };

      await DatabaseHelper.instance.updateUser(updatedUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 32),
                    _buildInfoCard(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        shadowColor: kPrimaryColor.withOpacity(0.3),
                        elevation: 10,
                      ),
                      child: const Text('SAVE CHANGES'),
                    ),
                  ],
                ),
              ),
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

  Widget _buildInfoCard() {
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
          _buildInputLabel('Full Name'),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
            validator: (value) => value!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Email Address'),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Phone Number'),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
            validator: (value) => value!.isEmpty ? 'Phone is required' : null,
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Security Password'),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kSecondaryColor),
      ),
    );
  }
}
