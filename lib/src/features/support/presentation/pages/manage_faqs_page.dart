// ============================================================
// manage_faqs_page.dart — Admin: FAQ Management Screen
// ============================================================
// Shows the admin a list of FAQ questions. Each question is a
// shortcut that customers can tap in the Support screen; the AI
// chatbot generates the answer live — no stored answers here.
//
// App bar actions:
//   • History icon — restores the default factory questions after
//     a confirmation dialog.
//   • "+" icon     — opens AddEditFAQPage to add a new question.
//
// If the FAQ table is empty (e.g. after all entries were deleted),
// seedFAQs() is automatically called to restore the defaults.
// ============================================================

import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'add_edit_faq_page.dart';

/// Admin screen for creating, editing, and deleting FAQ entries.
class ManageFAQsPage extends StatefulWidget {
  const ManageFAQsPage({super.key});

  @override
  State<ManageFAQsPage> createState() => _ManageFAQsPageState();
}

class _ManageFAQsPageState extends State<ManageFAQsPage> {
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    var faqs = await db.getAllFAQs();
    
    if (faqs.isEmpty) {
      await db.seedFAQs();
      faqs = await db.getAllFAQs();
    }

    setState(() {
      _faqs = faqs;
      _isLoading = false;
    });
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restore Defaults', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will reset the FAQ list to the original factory questions. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, minimumSize: const Size(100, 40)),
            child: const Text('RESTORE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.seedFAQs();
      _loadFAQs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default FAQs restored'), backgroundColor: kSuccessColor));
    }
  }

  Future<void> _deleteFAQ(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete FAQ', style: TextStyle(fontWeight: FontWeight.bold, color: kErrorColor)),
        content: const Text('Are you sure you want to remove this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor, minimumSize: const Size(100, 40)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteFAQ(id);
      _loadFAQs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FAQ deleted'), backgroundColor: kSecondaryColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('MANAGE FAQS'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: kSecondaryColor),
            tooltip: 'Restore Defaults',
            onPressed: _restoreDefaults,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: kPrimaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditFAQPage()),
              ).then((_) => _loadFAQs());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _faqs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) => _buildFAQCard(_faqs[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline_rounded, size: 80,
              color: kGreyMedium.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No questions yet', style: TextStyle(color: kTextSecondary)),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add the first FAQ question.',
            style: TextStyle(color: kGreyMedium, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(Map<String, dynamic> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kGreyLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Question icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: kPrimaryColor, size: 18),
            ),
            const SizedBox(width: 14),

            // Question text + AI badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq['question'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kSecondaryColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.smart_toy_outlined,
                          size: 12, color: kGreyMedium),
                      const SizedBox(width: 4),
                      Text(
                        'Answered by AI chatbot',
                        style: TextStyle(fontSize: 11, color: kGreyMedium),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: kPrimaryColor,
              tooltip: 'Edit question',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddEditFAQPage(faq: faq)),
              ).then((_) => _loadFAQs()),
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: kErrorColor,
              tooltip: 'Delete question',
              onPressed: () => _deleteFAQ(faq['id']),
            ),
          ],
        ),
      ),
    );
  }
}
