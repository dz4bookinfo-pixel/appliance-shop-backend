import 'dart:io' as io;
import 'package:dart_appwrite/dart_appwrite.dart';

Future<void> main(List<String> args) async {
  final String endpoint = io.Platform.environment['APPWRITE_ENDPOINT'] ?? 'http://appwrite:80/v1';
  final String projectId = io.Platform.environment['APPWRITE_PROJECT'] ?? '';
  final String apiKey = io.Platform.environment['APPWRITE_API_KEY'] ?? '';
  final String databaseId = io.Platform.environment['APPWRITE_DATABASE_ID'] ?? '';
  final String categoriesCollectionId = io.Platform.environment['APPWRITE_CATEGORIES_COLLECTION_ID'] ?? '';
  final String productsCollectionId = io.Platform.environment['APPWRITE_PRODUCTS_COLLECTION_ID'] ?? '';
  
  final client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId)
    ..setKey(apiKey);
  
  final databases = Databases(client);
  
  try {
    // Initialize categories
    final categories = [
      {'key': 'froid', 'label': 'Refrigeration'},
      {'key': 'pem', 'label': 'Small Appliances'},
      {'key': 'cuisson', 'label': 'Cooking'},
      {'key': 'clim', 'label': 'Air Conditioning'},
      {'key': 'linge', 'label': 'Laundry'}
    ];
    
    int categoriesCreated = 0;
    for (final cat in categories) {
      try {
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: categoriesCollectionId,
          documentId: cat['key'] as String,
          data: {
            'key': cat['key'],
            'label': cat['label'],
          },
        );
        categoriesCreated++;
      } catch (e) {
        print('Category ${cat['key']} already exists');
      }
    }
    
    print('Created $categoriesCreated categories');
    
    // Initialize sample products
    final products = [
      {'name': 'Refrigerator Pro', 'category': 'froid', 'price': 1200.0, 'description': 'High-quality refrigerator', 'active': true},
      {'name': 'Electric Stove', 'category': 'cuisson', 'price': 2500.0, 'description': 'Modern electric cooking stove', 'active': true},
    ];
    
    int productsCreated = 0;
    for (final product in products) {
      try {
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: productsCollectionId,
          documentId: DateTime.now().millisecondsSinceEpoch.toString(),
          data: {
            'name': product['name'],
            'category': product['category'],
            'price': product['price'],
            'description': product['description'],
            'images': [],
            'active': product['active'],
          },
        );
        productsCreated++;
      } catch (e) {
        print('Error creating product: $e');
      }
    }
    
    print('Created $productsCreated products');
    print('Catalog seeding completed successfully!');
  } catch (e) {
    print('Fatal error: $e');
    exit(1);
  }
}
