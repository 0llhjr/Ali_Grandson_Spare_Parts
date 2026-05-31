// ============================================================
// product_data.dart — Default Product Seed Data
// ============================================================
// This file defines the five starter products that are inserted
// into the database the very first time the app is installed.
//
// seedDatabase() is called from main.dart at startup.  It checks
// whether the products table is empty before inserting anything,
// so it never adds duplicates.
//
// Images are stored as raw bytes (Uint8List) in the database
// so no external file references are needed at runtime.
// ============================================================

import 'package:flutter/services.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';

/// Provides default spare-part products to pre-populate the app on first run.
class ProductData {
  /// The list of default products.
  /// Each map contains the product fields plus an `image_path` pointing to
  /// a bundled asset — the path is replaced by actual bytes before saving.
  static final List<Map<String, dynamic>> defaultProducts = [
    {
      'name': 'Brake Pad',
      'description': 'High-performance ceramic brake pads for smooth stopping power.',
      'image_path': 'lib/assets/Product_Data/brake_pad.jpeg',
      'type': 'Sedan',
      'brand': 'Brembo',
      'model': '2020-2023',
      'price': 25.500,
      'available': 50,
    },
    {
      'name': 'Oil Filter',
      'description': 'Premium engine oil filter for maximum filtration and engine protection.',
      'image_path': 'lib/assets/Product_Data/oil_filter.jpeg',
      'type': 'SUV',
      'brand': 'Bosch',
      'model': '2018-2022',
      'price': 5.800,
      'available': 100,
    },
    {
      'name': 'Spark Plug',
      'description': 'Iridium spark plugs for better fuel efficiency and reliable starts.',
      'image_path': 'lib/assets/Product_Data/spark_plug.jpg',
      'type': 'Coupe',
      'brand': 'NGK',
      'model': 'All Models',
      'price': 3.200,
      'available': 200,
    },
    {
      'name': 'Air Filter',
      'description': 'High-flow air filter to improve engine performance and longevity.',
      'image_path': 'lib/assets/Product_Data/air_filter.jpeg',
      'type': 'Truck',
      'brand': 'K&N',
      'model': '2015-2021',
      'price': 12.000,
      'available': 30,
    },
    {
      'name': 'Wiper Blades',
      'description': 'All-weather silicone wiper blades for crystal clear visibility.',
      'image_path': 'lib/assets/Product_Data/wiper_blades.jpg',
      'type': 'Hatchback',
      'brand': 'Rain-X',
      'model': 'Universal',
      'price': 8.500,
      'available': 75,
    },
  ];

  /// Inserts [defaultProducts] into the database if the products table is empty.
  /// Each product's image asset is loaded from the app bundle and converted to
  /// bytes before being saved, so the database is fully self-contained.
  static Future<void> seedDatabase() async {
    final db = DatabaseHelper.instance;

    // Only seed if no products exist yet (avoids inserting duplicates).
    final existingProducts = await db.getProducts();
    if (existingProducts.isEmpty) {
      for (var product in defaultProducts) {
        Uint8List? imageBytes;
        try {
          // Load the image from the assets folder bundled with the app.
          final ByteData data = await rootBundle.load(product['image_path']);
          imageBytes = data.buffer.asUint8List();
        } catch (e) {
          // If the image file is missing, continue without an image.
          print('Error loading image ${product['image_path']}: $e');
        }

        // Copy the product map so we can modify it without affecting the original.
        final productToInsert = Map<String, dynamic>.from(product);

        // Remove the asset path — the database stores bytes, not file paths.
        productToInsert.remove('image_path');
        productToInsert['image'] = imageBytes;

        await db.insertProduct(productToInsert);
      }
    }
  }
}
