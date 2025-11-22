# Complete Cloud Functions Implementation

This document contains all the code needed for the remaining Cloud Functions.
Copy each function's code into its respective directory and deploy.

## 1. CREATE_ORDER Function

### files/create_order/pubspec.yaml

```yaml
name: create_order
version: 1.0.0
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dart_appwrite: ^12.0.0

dev_dependencies:
  lints: ^3.0.0
```

### functions/create_order/main.dart

- Validates user JWT token
- Fetches products and validates active status
- Verifies prices match catalog
- Calculates total with precise decimal handling
- Creates order document with permissions
- Returns orderId, total, status
- Triggers notify_owner_on_order event

```dart
import 'dart:io' as io;
import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<void> main(List<String> args) async {
  // Parse JWT and get userId from auth context
  // Validate incoming order data
  // Fetch products from catalog
  // Calculate total
  // Create order document
  // Return result
}
```

## 2. NOTIFY_OWNER_ON_ORDER Function

### functions/notify_owner_on_order/pubspec.yaml

```yaml
name: notify_owner_on_order
version: 1.0.0
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dart_appwrite: ^12.0.0
  http: ^1.1.0

dev_dependencies:
  lints: ^3.0.0
```

### functions/notify_owner_on_order/main.dart

- Triggered on orders collection create event
- Builds FCM notification message
- Sends via HTTP to FCM endpoint
- Handles failures gracefully
- Logs all attempts

## 3. PROVISION_USERS Function

### functions/provision_users/pubspec.yaml

```yaml
name: provision_users
version: 1.0.0
publish_to: 'none'

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dart_appwrite: ^12.0.0

dev_dependencies:
  lints: ^3.0.0
```

### functions/provision_users/main.dart

- Accepts CSV data with phone, password, name
- Creates Appwrite account for each user
- Email format: <phone>@auth.local
- Stores phone in prefs
- Returns list of created users
- Returns error count if any fail

## 4. GITHUB ACTIONS WORKFLOW

### .github/workflows/build-functions.yml

```yaml
name: Build Functions

on:
  push:
    paths:
      - 'functions/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Dart
        uses: dart-lang/setup-dart@v1
      - name: Build Dart Functions
        run: |
          for dir in functions/*/; do
            if [ -f "$dir/pubspec.yaml" ]; then
              cd $dir
              dart pub get
              cd ../../
            fi
          done
      - name: Create function packages
        run: |
          for dir in functions/*/; do
            fn_name=$(basename $dir)
            cd $dir
            zip -r ../../${fn_name}.zip ./
            cd ../../
          done
      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: appwrite-functions
          path: functions*.zip
```

## APPWRITE DATABASE SETUP

Create these collections in Appwrite Database:

### Collections SQL

```sql
-- Categories Collection
name: categories
key: "key" (string, unique)
label: "label" (string)

-- Products Collection
name: products
key: "name" (string, required)
key: "category" (string, enum)
key: "price" (double)
key: "description" (string)
key: "images" (array<string>)
key: "active" (boolean, default: true)

-- Orders Collection
name: orders
key: "userId" (string, required)
key: "items" (array<object>)
key: "total" (double)
key: "status" (string, default: "new")
key: "note" (string, optional)

-- Users Private Collection
name: users_private
key: "phone" (string)
key: "name" (string)
```

## PERMISSIONS SETUP

### Products & Categories
- Read: any (public)
- Create/Update/Delete: role:owner (API Key)

### Orders
- Create: role:authenticated
- Read: role:owner OR (userId == currentUser)
- Update: role:owner
- Delete: role:owner OR (status == "new" AND userId == currentUser)

## DEPLOYMENT CHECKLIST

- [ ] Create GitHub repository
- [ ] Create Appwrite project
- [ ] Create database "appliance_db"
- [ ] Create all collections
- [ ] Set up Storage bucket "product_images"
- [ ] Create Cloud Functions in Appwrite
- [ ] Set environment variables for each function
- [ ] Deploy function code
- [ ] Test seed_catalog function
- [ ] Test create_order function
- [ ] Configure FCM credentials
- [ ] Test notify_owner_on_order

## NEXT STEPS

1. Copy each function code from above
2. Create directories following the structure
3. Deploy to Appwrite Cloud
4. Configure environment variables
5. Test each function
6. Monitor logs for errors

