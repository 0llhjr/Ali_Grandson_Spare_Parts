// ============================================================
// add_edit_faq_page.dart — Admin: Create or Edit FAQ Question
// ============================================================
// A dual-purpose form used for both creating and editing a FAQ.
//
// Behaviour depends on whether [faq] is passed in:
//   faq == null  → "Add" mode: blank form, saves a new question.
//   faq != null  → "Edit" mode: pre-filled, updates the question.
//
// Answers are NOT stored here. The AI chatbot answers every FAQ
// question live when a customer taps it in the Support screen.
// The admin's only job is to maintain the question list.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Form screen for creating or editing a FAQ question.
class AddEditFAQPage extends StatefulWidget {
  /// The existing FAQ map when editing, or null when creating a new entry.
  final Map<String, dynamic>? faq;

  const AddEditFAQPage({super.key, this.faq});

  @override
  State<AddEditFAQPage> createState() => _AddEditFAQPageState();
}

class _AddEditFAQPageState extends State<AddEditFAQPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();

  bool get _isEdit => widget.faq != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _questionController.text = widget.faq!['question'];
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _saveFAQ() async {
    if (!_formKey.currentState!.validate()) return;

    // Answer is always empty — answered live by the AI chatbot.
    final Map<String, dynamic> faqData = {
      'question': _questionController.text.trim(),
      'answer': '',
    };

    if (!_isEdit) {
      await DatabaseHelper.instance.insertFAQ(faqData);
    } else {
      faqData['id'] = widget.faq!['id'];
      await DatabaseHelper.instance.updateFAQ(faqData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Question updated' : 'Question added to FAQ list'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'EDIT QUESTION' : 'ADD QUESTION'),
        backgroundColor: AppColors.surface,
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
              _buildFormContainer(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveFAQ,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isEdit ? 'SAVE CHANGES' : 'ADD QUESTION',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: AppColors.grey400),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: AppColors.grey700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _isEdit ? Icons.edit_note_rounded : Icons.add_comment_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isEdit ? 'Edit FAQ Question' : 'Add a FAQ Question',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Type the question customers commonly ask. The AI chatbot will answer it automatically — no manual answer needed.',
          style: TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 16),
        // Info chip explaining the AI-answer model
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Answers are generated live by the AI support assistant when a customer taps this question.',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Customer Question'),
          TextFormField(
            controller: _questionController,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'e.g. How do I track my order?',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.help_outline_rounded, size: 20),
              ),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Question is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
