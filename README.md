# Appliance Shop Backend

Backend for appliance e-commerce app using Appwrite and Dart Cloud Functions.

## Overview

This repository contains the complete backend infrastructure for an appliance e-commerce platform:

- **Cloud Functions**: Dart-based serverless functions deployed on Appwrite
- **Database**: Appwrite Database with collections for products, categories, orders, and users
- **Storage**: Appwrite Storage bucket for product images
- **Authentication**: Phone-based authentication via email provisioning
- **Notifications**: FCM integration for owner notifications

## Project Structure

```
appliance-shop-backend/
├── functions/
│   ├── seed_catalog/          # Initialize product categories and sample data
│   ├── create_order/          # Create new order with validation
│   ├── notify_owner_on_order/ # Send FCM notifications to owner
│   ├── provision_users/       # Batch create users from CSV
│   └── generate_signed_image_url/ # Generate temporary image URLs (optional)
├── .github/workflows/
│   └── build-functions.yml    # CI/CD pipeline for function builds
└── README.md
```

## Appwrite Setup

### Database Structure

#### Collections

1. **categories**
   - `key` (string, unique): froid, pem, cuisson, clim, linge
   - `label` (string): Category name

2. **products**
   - `name` (string, required)
   - `category` (string, enum: froid|pem|cuisson|clim|linge)
   - `price` (number)
   - `description` (string)
   - `images` (array<string>): File IDs from Storage
   - `active` (boolean, default: true)
   - Indexes: category, name (text search)

3. **orders**
   - `userId` (string, required)
   - `items` (array<object>): [{productId, qty, priceSnapshot}]
   - `total` (number)
   - `status` (string, default: "new"): new, confirmed, shipped, cancelled
   - `note` (string, optional)
   - Indexes: userId, status, createdAt

4. **users_private** (optional)
   - Stores additional user data (phone, preferences)
   - `phone` (string)
   - `name` (string)

### Storage

- **Bucket**: `product_images`
- Stores product images with public read access

### Permissions & Security

#### Products & Categories
- **Read**: Public (anyone)
- **Create/Update/Delete**: API Key only (owner)

#### Orders
- **Create**: Authenticated users only
- **Read**: 
  - User can read their own orders (userId == currentUser)
  - Owner can read all orders
- **Update**: 
  - Owner can update status
  - User can cancel if status == "new"

#### Users
- **Create**: API Key only (provisioning)
- **Read**: User owns their record, owner reads all

## Environment Variables

Set these in your Appwrite Cloud Functions dashboard:

### Appwrite Configuration
```
APPWRITE_ENDPOINT=https://your-appwrite-endpoint.com/v1
APPWRITE_PROJECT=your_project_id
APPWRITE_API_KEY=your_api_key
APPWRITE_DATABASE_ID=appliance_db
APPWRITE_PRODUCTS_COLLECTION_ID=products_collection_id
APPWRITE_ORDERS_COLLECTION_ID=orders_collection_id
APPWRITE_CATEGORIES_COLLECTION_ID=categories_collection_id
APPWRITE_STORAGE_BUCKET_ID=product_images_bucket_id
```

### FCM Configuration (for notify_owner_on_order)
```
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
OWNER_DEVICE_TOKEN=owner_device_token_or
FCM_TOPIC_OWNER=owner-notify
```

## Cloud Functions

### 1. seed_catalog

Initialize product categories and sample data.

**Trigger**: Manual execution

**Input**: None (runs autonomously)

**Output**:
```json
{
  "categories_created": 5,
  "products_created": 10,
  "message": "Catalog initialized"
}
```

### 2. create_order

Create a new order with validation and calculations.

**Trigger**: HTTP POST

**Input**:
```json
{
  "items": [
    {
      "productId": "product_id_1",
      "qty": 2,
      "priceSnapshot": 1500.00
    }
  ],
  "note": "Optional delivery instructions"
}
```

**Output**:
```json
{
  "orderId": "order_doc_id",
  "total": 3000.00,
  "status": "new",
  "items_count": 2
}
```

**Workflow**:
1. Validates user session (JWT)
2. Fetches products to verify active status
3. Validates prices against current catalog
4. Calculates total with precision
5. Creates order document with proper permissions
6. Triggers notify_owner_on_order

### 3. notify_owner_on_order

Send FCM notifications to app owner when new orders arrive.

**Trigger**: Event on orders collection (documents.create)

**Behavior**:
- Builds notification message with order details
- Sends to FCM topic or device token
- Fails gracefully (logs error, doesn't block order creation)
- Includes order ID, total amount, item count

### 4. provision_users

Batch create users from CSV data.

**Trigger**: HTTP POST

**Input**:
```csv
phone,password,name
212612345678,password123,Ahmed
212687654321,password456,Fatima
```

**Output**:
```json
{
  "created": 2,
  "failed": 0,
  "users": [
    {"phone": "212612345678", "email": "212612345678@auth.local", "id": "user_id"}
  ]
}
```

**Security**: Only callable by owner/admin (API Key)

## Deployment

### Prerequisites

- Dart SDK installed
- Appwrite CLI installed
- GitHub account
- Appwrite Cloud account

### Deploy Functions

#### Option 1: Manual Deployment

```bash
# Build function
cd functions/seed_catalog
dart pub get
dart compile exe main.dart -o bin/app

# Deploy via Appwrite CLI
appwrite deploy function --functionId seed_catalog
```

#### Option 2: GitHub Actions (CI/CD)

On push to `functions/*/`:  Functions are automatically built and packaged as ZIP artifacts. Download and deploy manually to Appwrite.

### Configuration

1. Create Appwrite project and database
2. Create all collections and set permissions
3. Create Cloud Functions via Appwrite console
4. Set environment variables in each function
5. Deploy function code

## API Usage Examples

### Create Order

```bash
curl -X POST https://your-appwrite-endpoint/v1/functions/create_order/executions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer USER_JWT" \
  -d '{
    "items": [
      {"productId": "prod_1", "qty": 1, "priceSnapshot": 1500.00}
    ],
    "note": "Urgent delivery"
  }'
```

### Seed Catalog

```bash
curl -X POST https://your-appwrite-endpoint/v1/functions/seed_catalog/executions \
  -H "Authorization: Bearer API_KEY"
```

## Security Considerations

1. **API Key Management**: Keep API keys in Appwrite environment variables, never in code
2. **User Permissions**: Use role-based permissions (owner vs user)
3. **Data Validation**: All inputs validated before processing
4. **FCM Credentials**: Store Firebase credentials securely
5. **Price Verification**: Prices validated against current catalog
6. **Order Immutability**: Orders locked after confirmation

## Architecture

- **Stateless Functions**: All functions are stateless and can scale horizontally
- **Event-Driven**: Functions triggered by HTTP, events, or schedules
- **Atomic Operations**: Database transactions ensure consistency
- **Async Notifications**: FCM sends asynchronously, doesn't block orders

## Contributing

1. Clone repository
2. Create feature branch
3. Modify functions in `functions/*/`
4. Update README if needed
5. Push and create Pull Request

## License

MIT
