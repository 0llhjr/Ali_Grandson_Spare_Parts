// ============================================================
// add_product_page.dart — Admin: Add New Product Screen
// ============================================================
// The admin fills in this form to add a new spare part to the
// catalogue.  Required fields: name, brand, type, compatibility,
// price, quantity, and a product photo.
//
// After saving:
//   • The product is inserted into the database.
//   • All registered customers receive a "New Arrival" email.
//
// Image handling:
//   • The admin taps the image area to open the device gallery.
//   • The selected image is resized (max 800 px wide, quality 50%)
//     and stored as bytes (Uint8List) in the database.
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/email_service.dart';
import 'package:alis_grandson_app/src/shared/utils/email_templates.dart';

/// Form screen for creating a new spare-part product listing.
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _availableController = TextEditingController();
  Uint8List? _imageBytes;
  bool _isSaving = false;
  String? _selectedVehicleType;
  final EmailService _emailService = EmailService();

  static const _vehicleTypes = [
    'Sedan', 'SUV', 'Pickup Truck', 'Van', 'Hatchback', 'Universal',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image.'), backgroundColor: kWarningColor),
        );
        return;
      }
      
      setState(() => _isSaving = true);
      
      final product = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'image': _imageBytes,
        'type': _typeController.text,
        'brand': _brandController.text,
        'model': _modelController.text,
        'price': double.parse(_priceController.text),
        'available': int.parse(_availableController.text),
        'vehicle_type': _selectedVehicleType,
      };
      await DatabaseHelper.instance.insertProduct(product);

      // Notify all users about new product
      _notifyUsersAboutNewProduct(_nameController.text, _descriptionController.text);

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New product listed and users notified!'), backgroundColor: kSuccessColor),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _notifyUsersAboutNewProduct(String name, String description) async {
    final users = await DatabaseHelper.instance.getUsers();
    for (var user in users) {
      if (user['email'] != null) {
        await _emailService.sendGoogleEmail(
          recipientEmails: user['email'],
          subject: 'New Arrival: $name',
          htmlBody: await EmailTemplates.newProductAdded(user['name'] ?? user['username'], name, description),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('ADD NEW PART'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildImagePicker(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  _buildTextField(_nameController, 'Part Name', Icons.title, 'e.g. Brake Pads'),
                  const SizedBox(height: 16),
                  _buildTextField(_descriptionController, 'Description', Icons.description_outlined, 'Describe the product...', maxLines: 3),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Technical Specifications'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_brandController, 'Brand', Icons.branding_watermark_outlined, 'e.g. Bosch')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_typeController, 'Type', Icons.category_outlined, 'e.g. Engine')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildVehicleTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(_modelController, 'Compatibility', Icons.car_repair, 'e.g. 2020-2023 Models'),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Pricing & Inventory'),
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
                    onPressed: _isSaving ? null : _addProduct,
                    style: ElevatedButton.styleFrom(shadowColor: kPrimaryColor.withOpacity(0.3), elevation: 10),
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('LIST PRODUCT'),
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreyLight, width: 2),
        ),
        child: _imageBytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo_outlined, size: 40, color: kPrimaryColor),
                  ),
                  const SizedBox(height: 12),
                  const Text('Upload Product Photo', style: TextStyle(fontWeight: FontWeight.bold, color: kSecondaryColor)),
                  const Text('JPG or PNG, max 5MB', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                ],
              ),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedVehicleType,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: Icon(Icons.directions_car_outlined, size: 20),
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
    );
  }
}
