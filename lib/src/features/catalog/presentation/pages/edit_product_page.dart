// ============================================================
// edit_product_page.dart — Admin: Edit Existing Product Screen
// ============================================================
// Pre-fills all product fields from the database so the admin
// can change any detail (name, price, stock, image, etc.).
//
// Special restock logic:
//   • The old stock level is saved when the page loads (_oldStock).
//   • When the admin saves, if _oldStock was 0 and the new stock
//     is > 0, all customers receive a "Back in Stock" email.
//
// Image handling is the same as AddProductPage: tap to pick from
// gallery, stored as bytes in the database.
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

/// Form screen for editing an existing spare-part product.
class EditProductPage extends StatefulWidget {
  /// The database id of the product to be edited.
  final int productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _availableController = TextEditingController();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isSaving = false;
  int _oldStock = 0;
  String? _selectedVehicleType;
  final EmailService _emailService = EmailService();

  static const _vehicleTypes = [
    'Sedan', 'SUV', 'Pickup Truck', 'Van', 'Hatchback', 'Universal',
  ];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await DatabaseHelper.instance.getProduct(widget.productId);
    if (product != null) {
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _typeController.text = product['type'] ?? '';
      _brandController.text = product['brand'] ?? '';
      _modelController.text = product['model'] ?? '';
      _priceController.text = product['price'].toString();
      _oldStock = product['available'] as int;
      _availableController.text = _oldStock.toString();
      final rawVehicleType = product['vehicle_type'] as String?;
      final image = await DatabaseHelper.instance.getProductImage(widget.productId);
      setState(() {
        _selectedVehicleType = (_vehicleTypes.contains(rawVehicleType)) ? rawVehicleType : null;
        _imageBytes = image;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final newStock = int.parse(_availableController.text);
      final product = {
        'id': widget.productId,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'image': _imageBytes,
        'type': _typeController.text,
        'brand': _brandController.text,
        'model': _modelController.text,
        'price': double.parse(_priceController.text),
        'available': newStock,
        'vehicle_type': _selectedVehicleType,
      };
      await DatabaseHelper.instance.updateProduct(product);

      // Check if stock was filled from zero
      if (_oldStock == 0 && newStock > 0) {
        await _notifyUsersAboutRestock(_nameController.text);
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated and users notified if restocked!'), backgroundColor: kSuccessColor, behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _notifyUsersAboutRestock(String name) async {
    final users = await DatabaseHelper.instance.getUsers();
    for (var user in users) {
      if (user['email'] != null) {
        await _emailService.sendGoogleEmail(
          recipientEmails: user['email'],
          subject: 'Back in Stock: $name',
          htmlBody: await EmailTemplates.productBackInStock(user['name'] ?? user['username'], name),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('EDIT PRODUCT'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildImageSection(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Product Details'),
                        const SizedBox(height: 16),
                        _buildTextField(_nameController, 'Part Name', Icons.title_rounded, 'Enter part name'),
                        const SizedBox(height: 16),
                        _buildTextField(_descriptionController, 'Description', Icons.description_outlined, 'Provide a clear description', maxLines: 3),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Specifications'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_brandController, 'Brand', Icons.branding_watermark_outlined, 'e.g. NGK')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_typeController, 'Type', Icons.category_outlined, 'e.g. Engine')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildVehicleTypeDropdown(),
                        const SizedBox(height: 16),
                        _buildTextField(_modelController, 'Compatibility', Icons.car_repair_rounded, 'Models/Years'),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Pricing & Availability'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_priceController, 'Price (OMR)', Icons.payments_outlined, '0.000', keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_availableController, 'Quantity', Icons.inventory_2_outlined, '0', keyboardType: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 48),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _updateProduct,
                          style: ElevatedButton.styleFrom(shadowColor: kPrimaryColor.withOpacity(0.3), elevation: 8),
                          child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE CHANGES'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            side: const BorderSide(color: kGreyMedium),
                            foregroundColor: kTextSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSecondaryColor, letterSpacing: 1.2),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Image', style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreyLight),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Stack(
              children: [
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(_imageBytes!, width: double.infinity, height: 200, fit: BoxFit.cover),
                  )
                else
                  const Center(child: Icon(Icons.image_not_supported_outlined, size: 50, color: kGreyMedium)),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVehicleType,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: Icon(Icons.directions_car_outlined, size: 20, color: kGreyMedium),
      ),
      hint: const Text('Select vehicle type'),
      items: _vehicleTypes
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => setState(() => _selectedVehicleType = v),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: kGreyMedium),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
    );
  }
}
