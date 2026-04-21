# Restaurant Service

The Restaurant Service is a comprehensive microservice handling restaurant operations, menu management, order processing, and delivery coordination in the food delivery platform. It manages restaurants, menu items, shopping carts, user addresses, and order lifecycle.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Database Models](#database-models)
- [API Endpoints](#api-endpoints)
- [Message Queue Integration](#message-queue-integration)
- [Business Logic](#business-logic)
- [Error Handling](#error-handling)
- [Development](#development)
- [Deployment](#deployment)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

The Restaurant Service is the core operational hub for managing restaurant-related activities including:

- Restaurant registration and management
- Menu item creation and updates
- Shopping cart operations
- User address management
- Order creation and fulfillment
- Delivery rider assignment
- Order status tracking

This service runs on **Port 5001** and integrates with MongoDB for data persistence, RabbitMQ for asynchronous messaging, and communicates with other microservices for uploads and real-time updates.

## Features

- **Restaurant Management**
  - Create and register restaurants
  - Update restaurant information (name, description, location, contact)
  - Toggle restaurant open/closed status
  - Geospatial queries for nearby restaurants
  - Restaurant verification status tracking

- **Menu Item Management**
  - Add menu items with images
  - Edit and delete menu items
  - Categorize items
  - Price and availability management
  - Image upload to external service

- **Shopping Cart**
  - Add items to cart
  - Update cart quantities
  - Remove items from cart
  - Cart persistence per user
  - Multi-restaurant cart validation

- **User Address Management**
  - Create and store delivery addresses
  - Set default address
  - Update address information
  - Delete addresses

- **Order Management**
  - Create orders from cart
  - Calculate delivery distance and charges
  - Order status tracking (pending, confirmed, preparing, ready, out for delivery, delivered)
  - Fetch user orders and restaurant orders
  - Real-time order status updates

- **Delivery Integration**
  - Assign riders to orders
  - Rider order tracking
  - Rider status updates
  - Order delivery history

- **Message Queue Integration**
  - Publish order events via RabbitMQ
  - Consume payment confirmation events
  - Async order processing

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js 5.x
- **Database**: MongoDB with Mongoose 9.x
- **Message Queue**: RabbitMQ with amqplib
- **File Upload**: Multer 2.x, datauri
- **Authentication**: JWT (jsonwebtoken 9.x)
- **HTTP Client**: Axios for service communication
- **Utilities**: CORS, dotenv
- **Development**: Concurrently, TypeScript compiler

## Prerequisites

Before you begin, ensure you have installed:

- **Node.js** (v16.x or higher) - [Download](https://nodejs.org/)
- **npm** (v8.x or higher) - Comes with Node.js
- **MongoDB** (local or Atlas) - [Download](https://www.mongodb.com/try/download/community)
- **RabbitMQ** (for message queuing) - [Download](https://www.rabbitmq.com/download.html)
- **Git** - [Download](https://git-scm.com/)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/food-delivery-platform.git
cd services/backend/restaurant-service
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

### 4. Update Environment Variables

Edit `.env` with your configuration:

```env
# Server Configuration
PORT=5001

# Database Configuration
MONGO_URI=mongodb://localhost:27017/zomato_clone

# Authentication
JWT_SEC=your_jwt_secret_key_here_make_it_strong

# External Services
UTILS_SERVICE=http://localhost:5002
REALTIME_SERVICE=http://localhost:5004
INTERNAL_SERVICE_KEY=your_internal_service_key

# Message Queue
RABBITMQ_URL=amqp://guest:guest@localhost:5672
PAYMENT_QUEUE=payment_event
RIDER_QUEUE=rider_queue
ORDER_READY_QUEUE=order_ready_queue
```

**Environment Variables Explained:**

| Variable               | Description                        | Example                                                    |
| ---------------------- | ---------------------------------- | ---------------------------------------------------------- |
| `PORT`                 | Service listening port             | `5001`                                                     |
| `MONGO_URI`            | MongoDB connection string          | `mongodb+srv://user:pass@cluster.mongodb.net/zomato_clone` |
| `JWT_SEC`              | JWT secret for token verification  | `your-super-secret-key`                                    |
| `UTILS_SERVICE`        | Utils service URL for file uploads | `http://localhost:5002`                                    |
| `REALTIME_SERVICE`     | Realtime service URL               | `http://localhost:5004`                                    |
| `INTERNAL_SERVICE_KEY` | Internal API authentication key    | `your-internal-key`                                        |
| `RABBITMQ_URL`         | RabbitMQ connection string         | `amqp://guest:guest@localhost:5672`                        |
| `PAYMENT_QUEUE`        | Payment event queue name           | `payment_event`                                            |
| `RIDER_QUEUE`          | Rider assignment queue             | `rider_queue`                                              |
| `ORDER_READY_QUEUE`    | Order ready queue                  | `order_ready_queue`                                        |

## Project Structure

```
restaurant-service/
├── src/
│   ├── config/
│   │   ├── db.ts                 # MongoDB/Mongoose connection
│   │   ├── datauri.ts            # File buffer conversion
│   │   ├── order.publisher.ts    # RabbitMQ event publisher
│   │   ├── payment.consumer.ts   # RabbitMQ payment consumer
│   │   └── rabbitmq.ts           # RabbitMQ connection setup
│   ├── controllers/
│   │   ├── restaraunt.ts         # Restaurant operations
│   │   ├── menuitem.ts           # Menu item management
│   │   ├── cart.ts               # Shopping cart operations
│   │   ├── address.ts            # Address management
│   │   └── order.ts              # Order processing
│   ├── middlewares/
│   │   ├── isAuth.ts             # JWT authentication & role check
│   │   ├── multer.ts             # File upload middleware
│   │   └── trycatch.ts           # Error handling wrapper
│   ├── models/
│   │   ├── Restaurant.ts         # Restaurant schema
│   │   ├── MenuItems.ts          # Menu items schema
│   │   ├── Cart.ts               # Shopping cart schema
│   │   ├── Address.ts            # User address schema
│   │   └── Order.ts              # Order schema
│   ├── routes/
│   │   ├── restaraunt.ts         # Restaurant routes
│   │   ├── menuitem.ts           # Menu item routes
│   │   ├── cart.ts               # Cart routes
│   │   ├── address.ts            # Address routes
│   │   └── order.ts              # Order routes
│   └── index.ts                  # Application entry point
├── dist/                         # Compiled JavaScript (generated)
├── .env                          # Environment variables (not in repo)
├── .env.example                  # Environment template
├── .gitignore                    # Git ignore rules
├── Dockerfile                    # Docker configuration
├── package.json                  # Project dependencies
├── tsconfig.json                 # TypeScript configuration
└── README.md                     # This file
```

## Database Models

### Restaurant Model

```typescript
{
  name: String (required),
  description: String,
  image: String (required),
  ownerId: String (required),
  phone: Number (required),
  isVerified: Boolean,
  isOpen: Boolean (default: false),
  autoLocation: {
    type: "Point",
    coordinates: [longitude, latitude],
    formattedAddress: String
  },
  createdAt: Date,
  updatedAt: Date
}
```

### Menu Item Model

```typescript
{
  name: String (required),
  description: String,
  price: Number (required),
  image: String (required),
  restaurantId: ObjectId (required),
  category: String,
  availability: Boolean (default: true),
  preparationTime: Number,
  createdAt: Date,
  updatedAt: Date
}
```

### Cart Model

```typescript
{
  userId: ObjectId (required),
  itemId: ObjectId (required),
  restaurantId: ObjectId (required),
  quantity: Number (required),
  price: Number,
  createdAt: Date,
  updatedAt: Date
}
```

### Order Model

```typescript
{
  userId: ObjectId (required),
  items: Array<{itemId, quantity, price}>,
  totalAmount: Number,
  deliveryCharge: Number,
  distance: Number,
  restaurantId: ObjectId,
  addressId: ObjectId,
  riderId: ObjectId,
  status: String (pending/confirmed/preparing/ready/out_for_delivery/delivered),
  paymentStatus: String,
  paymentMethod: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Address Model

```typescript
{
  userId: ObjectId (required),
  street: String (required),
  city: String,
  state: String,
  pinCode: String,
  latitude: Number,
  longitude: Number,
  isDefault: Boolean (default: false),
  createdAt: Date,
  updatedAt: Date
}
```

## API Endpoints

### Restaurant Endpoints

#### Create Restaurant

**Endpoint:** `POST /api/restaurant/new`

**Authentication:** Required (seller role)

**Headers:**

```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Request Body:**

```
name: "Pizza Palace" (string, required)
description: "Authentic Italian Pizza" (string)
phone: 9876543210 (number, required)
latitude: 28.7041 (number, required)
longitude: 77.1025 (number, required)
formattedAddress: "123 MG Road, Delhi" (string)
image: <file> (multipart, required)
```

**Response (201 Created):**

```json
{
  "message": "Restaurant created successfully",
  "restaurant": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "Pizza Palace",
    "image": "https://...",
    "isVerified": false,
    "isOpen": false
  }
}
```

#### Get My Restaurant

**Endpoint:** `GET /api/restaurant/my`

**Authentication:** Required (seller role)

**Response (200 OK):**

```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "Pizza Palace",
  "phone": 9876543210,
  "image": "https://...",
  "isVerified": true,
  "isOpen": true
}
```

#### Update Restaurant

**Endpoint:** `PUT /api/restaurant/edit`

**Authentication:** Required (seller role)

**Request Body:**

```json
{
  "name": "Pizza Palace - Updated",
  "description": "Best Pizza in Town"
}
```

#### Update Restaurant Status

**Endpoint:** `PUT /api/restaurant/status`

**Authentication:** Required (seller role)

**Request Body:**

```json
{
  "isOpen": true
}
```

#### Get Nearby Restaurants

**Endpoint:** `GET /api/restaurant/all`

**Authentication:** Required

**Query Parameters:**

```
latitude: 28.7041
longitude: 77.1025
```

**Response (200 OK):**

```json
{
  "restaurants": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "name": "Pizza Palace",
      "distance": 2.5
    }
  ]
}
```

#### Get Single Restaurant

**Endpoint:** `GET /api/restaurant/:id`

**Authentication:** Required

**Response (200 OK):**

```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "Pizza Palace",
  "menu": []
}
```

### Menu Item Endpoints

#### Add Menu Item

**Endpoint:** `POST /api/item/new`

**Authentication:** Required (seller role)

**Headers:**

```
Content-Type: multipart/form-data
```

**Request Body:**

```
restaurantId: "507f1f77bcf86cd799439011" (string, required)
name: "Margherita Pizza" (string, required)
price: 250 (number, required)
description: "Classic pizza with tomato and basil" (string)
category: "Pizzas" (string)
image: <file> (multipart, required)
```

#### Get Menu Items

**Endpoint:** `GET /api/item/:restaurantId`

**Response (200 OK):**

```json
{
  "items": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "name": "Margherita Pizza",
      "price": 250,
      "image": "https://..."
    }
  ]
}
```

#### Update Menu Item

**Endpoint:** `PUT /api/item/:id`

**Authentication:** Required (seller role)

**Request Body:**

```json
{
  "price": 300,
  "availability": true
}
```

### Cart Endpoints

#### Add to Cart

**Endpoint:** `POST /api/cart/add`

**Authentication:** Required

**Request Body:**

```json
{
  "itemId": "507f1f77bcf86cd799439012",
  "restaurantId": "507f1f77bcf86cd799439011",
  "quantity": 2
}
```

#### Get Cart

**Endpoint:** `GET /api/cart`

**Authentication:** Required

**Response (200 OK):**

```json
{
  "items": [
    {
      "itemId": {...},
      "quantity": 2,
      "price": 250
    }
  ],
  "total": 500
}
```

#### Update Cart Item

**Endpoint:** `PUT /api/cart/:itemId`

**Authentication:** Required

**Request Body:**

```json
{
  "quantity": 3
}
```

#### Remove from Cart

**Endpoint:** `DELETE /api/cart/:itemId`

**Authentication:** Required

### Address Endpoints

#### Create Address

**Endpoint:** `POST /api/address/new`

**Authentication:** Required

**Request Body:**

```json
{
  "street": "123 Main Street",
  "city": "Delhi",
  "state": "Delhi",
  "pinCode": "110001",
  "latitude": 28.7041,
  "longitude": 77.1025,
  "isDefault": true
}
```

#### Get Addresses

**Endpoint:** `GET /api/address`

**Authentication:** Required

#### Update Address

**Endpoint:** `PUT /api/address/:id`

**Authentication:** Required

#### Delete Address

**Endpoint:** `DELETE /api/address/:id`

**Authentication:** Required

### Order Endpoints

#### Create Order

**Endpoint:** `POST /api/order/new`

**Authentication:** Required

**Request Body:**

```json
{
  "addressId": "507f1f77bcf86cd799439013",
  "paymentMethod": "card"
}
```

**Response (201 Created):**

```json
{
  "message": "Order created successfully",
  "order": {
    "_id": "order-123",
    "totalAmount": 550,
    "deliveryCharge": 50,
    "status": "pending"
  }
}
```

#### Get My Orders

**Endpoint:** `GET /api/order/myorder`

**Authentication:** Required

#### Get Single Order

**Endpoint:** `GET /api/order/:id`

**Authentication:** Required

#### Get Restaurant Orders

**Endpoint:** `GET /api/order/restaurant/:restaurantId`

**Authentication:** Required (seller role)

#### Update Order Status

**Endpoint:** `PUT /api/order/:orderId`

**Authentication:** Required (seller role)

**Request Body:**

```json
{
  "status": "preparing"
}
```

#### Get Order for Payment

**Endpoint:** `GET /api/order/payment/:id`

**Response (200 OK):**

```json
{
  "_id": "order-123",
  "totalAmount": 550,
  "items": []
}
```

## Message Queue Integration

### RabbitMQ Queues

#### Payment Queue

- **Name:** `payment_event`
- **Purpose:** Receives payment confirmation events
- **Payload:**

```json
{
  "orderId": "order-123",
  "status": "completed",
  "transactionId": "txn-456"
}
```

#### Rider Queue

- **Name:** `rider_queue`
- **Purpose:** Receives rider assignment events
- **Payload:**

```json
{
  "orderId": "order-123",
  "riderId": "rider-789"
}
```

#### Order Ready Queue

- **Name:** `order_ready_queue`
- **Purpose:** Publishes when orders are ready for pickup
- **Payload:**

```json
{
  "orderId": "order-123",
  "restaurantId": "restaurant-111",
  "readyAt": "2024-01-15T10:30:00Z"
}
```

## Business Logic

### Order Creation Flow

1. **Cart Validation**: Check cart has items from single restaurant
2. **Address Validation**: Verify delivery address exists
3. **Distance Calculation**: Calculate distance using Haversine formula
4. **Delivery Charge**: Calculate based on distance
5. **Total Amount**: Sum items + delivery charge
6. **Order Creation**: Create order in pending status
7. **Cart Clearing**: Clear user's cart
8. **Event Publishing**: Publish order event to RabbitMQ
9. **Real-time Notification**: Emit notification to restaurant via realtime service

### Distance Calculation

```
Using Haversine Formula:
- Distance = 2 * R * arcsin(sqrt(sin²((lat2-lat1)/2) + cos(lat1) * cos(lat2) * sin²((lon2-lon1)/2)))
- R = Earth radius (6371 km)
- Returns distance in kilometers
```

### Order Status Workflow

```
pending
  ↓
confirmed (restaurant confirms order)
  ↓
preparing (restaurant starts preparation)
  ↓
ready (order ready for pickup)
  ↓
out_for_delivery (rider picks up order)
  ↓
delivered (rider completes delivery)
```

## Error Handling

All endpoints implement comprehensive error handling with try-catch middleware.

### Common Error Responses

| Status | Error                        | Cause                           |
| ------ | ---------------------------- | ------------------------------- |
| 400    | Cart is empty                | No items in user's cart         |
| 400    | Invalid Cart Data            | Cart item data is corrupted     |
| 400    | Please give all details      | Missing required fields         |
| 400    | Please give image            | No image uploaded               |
| 401    | Unauthorized / Please Login  | Missing or invalid JWT          |
| 403    | Forbidden                    | Insufficient permissions        |
| 404    | Address Not found            | Delivery address doesn't exist  |
| 404    | No Restaurant found          | Restaurant not found for seller |
| 500    | Failed to create file buffer | Image processing error          |

## Development

### Run Development Server

```bash
npm run dev
```

### Build for Production

```bash
npm run build
```

### Start Production Server

```bash
npm start
```

## Deployment

### Docker Deployment

Build Docker image:

```bash
docker build -t restaurant-service:latest .
```

Run container:

```bash
docker run -p 5001:5001 \
  -e PORT=5001 \
  -e MONGO_URI=mongodb://mongo:27017/zomato_clone \
  -e JWT_SEC=your-secret-key \
  -e RABBITMQ_URL=amqp://rabbitmq:5672 \
  -e UTILS_SERVICE=http://utils-service:5002 \
  -e REALTIME_SERVICE=http://realtime-service:5004 \
  -e INTERNAL_SERVICE_KEY=your-internal-key \
  restaurant-service:latest
```

### Docker Compose

```yaml
restaurant-service:
  build: ./restaurant-service
  env_file:
    - ./restaurant-service/.env
  ports:
    - "5001:5001"
  depends_on:
    - mongodb
    - rabbitmq
  restart: unless-stopped
```

### Kubernetes Deployment

See the `food-delivery-k8s/` directory for Kubernetes manifests.

## Examples

### Example 1: Create Restaurant

```bash
curl -X POST http://localhost:5001/api/restaurant/new \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "name=Pizza Palace" \
  -F "description=Authentic Italian Pizza" \
  -F "phone=9876543210" \
  -F "latitude=28.7041" \
  -F "longitude=77.1025" \
  -F "formattedAddress=123 MG Road, Delhi" \
  -F "image=@/path/to/image.jpg"
```

### Example 2: Add Menu Item

```bash
curl -X POST http://localhost:5001/api/item/new \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "restaurantId=507f1f77bcf86cd799439011" \
  -F "name=Margherita Pizza" \
  -F "price=250" \
  -F "category=Pizzas" \
  -F "image=@/path/to/item.jpg"
```

### Example 3: Create Order

```bash
curl -X POST http://localhost:5001/api/order/new \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "addressId": "507f1f77bcf86cd799439013",
    "paymentMethod": "card"
  }'
```

## Troubleshooting

### MongoDB Connection Error

**Error:** `connect ECONNREFUSED`

**Solution:**

- Ensure MongoDB is running
- Check MONGO_URI in .env
- Verify database name is correct

### RabbitMQ Connection Error

**Error:** `Connection refused on amqp://localhost`

**Solution:**

- Ensure RabbitMQ is running
- Check RABBITMQ_URL in .env
- Verify credentials are correct

### Image Upload Failed

**Error:** `Failed to create file buffer`

**Solution:**

- Verify file is a valid image format
- Check Utils Service is running
- Verify UTILS_SERVICE URL in .env

### JWT Token Issues

**Error:** `Unauthorized` or `Invalid token`

**Solution:**

- Verify token is valid and not expired
- Check JWT_SEC matches other services
- Ensure token is in Authorization header

## Security Considerations

1. **JWT Secret**: Use strong random string (32+ characters)
2. **API Key**: Secure INTERNAL_SERVICE_KEY
3. **File Upload**: Validate file types and sizes
4. **Input Validation**: Validate all inputs before processing
5. **Database**: Use connection strings with authentication
6. **CORS**: Configure allowed origins in production

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/your-feature`
5. Create a Pull Request

## License

This project is licensed under the ISC License.
