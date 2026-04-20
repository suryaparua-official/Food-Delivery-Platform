# Rider Service

The Rider Service is a comprehensive microservice for managing delivery riders, their profiles, availability status, and order delivery operations. It handles rider registration, verification, order acceptance, and real-time delivery tracking in the food delivery platform.

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

The Rider Service manages the delivery partner ecosystem of the platform. It handles:

- Rider profile creation with identity verification
- Availability status management
- Order acceptance and assignment
- Real-time delivery status updates
- Location tracking during deliveries
- Rider verification status by admin

This service runs on **Port 5005** and integrates with MongoDB for persistent storage, RabbitMQ for asynchronous order events, and communicates with other microservices for delivery coordination.

## Features

- **Rider Profile Management**
  - Rider registration and profile creation
  - Identity verification (Aadhar, Driving License)
  - Profile picture upload
  - Contact information storage
  - Location coordinates for availability

- **Availability Management**
  - Toggle rider availability status
  - Track last active time
  - Real-time availability updates
  - Visibility to order matching system

- **Order Management**
  - Accept delivery orders
  - Fetch current assigned order
  - View delivery history
  - Order assignment via RabbitMQ

- **Delivery Tracking**
  - Update order status during delivery
  - Real-time location updates
  - Delivery completion tracking
  - Integration with realtime service

- **Verification System**
  - Admin verification status
  - Document validation (Aadhar, Driving License)
  - Rider account status management
  - Trust score tracking

- **Geospatial Features**
  - Location-based rider search
  - Nearby rider availability
  - Distance calculation for assignments
  - MongoDB 2dsphere indexing

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
cd services/backend/rider-service
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
PORT=5005

# Database Configuration
MONGO_URI=mongodb://localhost:27017/zomato_clone

# Authentication
JWT_SEC=your_jwt_secret_key_here_make_it_strong

# External Services
UTILS_SERVICE=http://localhost:5002
REALTIME_SERVICE=http://localhost:5004
RESTAURANT_SERVICE=http://localhost:5001
INTERNAL_SERVICE_KEY=your_internal_service_key

# Message Queue
RABBITMQ_URL=amqp://guest:guest@localhost:5672
RIDER_QUEUE=rider_queue
ORDER_READY_QUEUE=order_ready_queue
```

**Environment Variables Explained:**

| Variable               | Description                            | Example                                                    |
| ---------------------- | -------------------------------------- | ---------------------------------------------------------- |
| `PORT`                 | Service listening port                 | `5005`                                                     |
| `MONGO_URI`            | MongoDB connection string              | `mongodb+srv://user:pass@cluster.mongodb.net/zomato_clone` |
| `JWT_SEC`              | JWT secret for token verification      | `your-super-secret-key`                                    |
| `UTILS_SERVICE`        | Utils service URL for file uploads     | `http://localhost:5002`                                    |
| `REALTIME_SERVICE`     | Realtime service URL for notifications | `http://localhost:5004`                                    |
| `RESTAURANT_SERVICE`   | Restaurant service URL                 | `http://localhost:5001`                                    |
| `INTERNAL_SERVICE_KEY` | Internal API authentication key        | `your-internal-key`                                        |
| `RABBITMQ_URL`         | RabbitMQ connection string             | `amqp://guest:guest@localhost:5672`                        |
| `RIDER_QUEUE`          | Rider assignment queue                 | `rider_queue`                                              |
| `ORDER_READY_QUEUE`    | Order ready event queue                | `order_ready_queue`                                        |

## Project Structure

```
rider-service/
├── src/
│   ├── config/
│   │   ├── db.ts                      # MongoDB/Mongoose connection
│   │   ├── datauri.ts                 # File buffer conversion
│   │   ├── orderReady.consumer.ts     # RabbitMQ order ready consumer
│   │   └── rabbitmq.ts                # RabbitMQ connection setup
│   ├── controllers/
│   │   └── rider.ts                   # Rider operations (profile, orders)
│   ├── middlewares/
│   │   ├── isAuth.ts                  # JWT authentication & role check
│   │   ├── multer.ts                  # File upload middleware
│   │   └── trycatch.ts                # Error handling wrapper
│   ├── model/
│   │   └── Rider.ts                   # Rider schema
│   ├── routes/
│   │   └── rider.ts                   # Rider routes
│   └── index.ts                       # Application entry point
├── dist/                              # Compiled JavaScript (generated)
├── .env                               # Environment variables (not in repo)
├── .env.example                       # Environment template
├── .gitignore                         # Git ignore rules
├── Dockerfile                         # Docker configuration
├── package.json                       # Project dependencies
├── tsconfig.json                      # TypeScript configuration
└── README.md                          # This file
```

## Database Models

### Rider Model

```typescript
{
  userId: String (required, unique),
  picture: String (required),
  phoneNumber: String (required, trimmed),
  aadharNumber: String (required),
  drivingLicenseNumber: String (required),
  isVerified: Boolean (default: false),
  location: {
    type: "Point",
    coordinates: [longitude, latitude]
  },
  isAvailble: Boolean (default: false),
  lastActiveAt: Date (default: now),
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**

- 2dsphere index on `location` field for geospatial queries
- Unique index on `userId` for profile lookup

## API Endpoints

### Rider Profile Endpoints

#### Create Rider Profile

**Endpoint:** `POST /api/rider/new`

**Authentication:** Required (rider role)

**Headers:**

```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Request Body:**

```
phoneNumber: "9876543210" (string, required)
aadharNumber: "123456789012" (string, required)
drivingLicenseNumber: "DL12AB0012345" (string, required)
latitude: 28.7041 (number, required)
longitude: 77.1025 (number, required)
picture: <file> (multipart, required)
```

**Response (201 Created):**

```json
{
  "message": "Rider profile created successfully",
  "riderProfile": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "user123",
    "phoneNumber": "9876543210",
    "isVerified": false,
    "isAvailble": false,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

#### Get My Profile

**Endpoint:** `GET /api/rider/myprofile`

**Authentication:** Required (rider role)

**Response (200 OK):**

```json
{
  "_id": "507f1f77bcf86cd799439011",
  "userId": "user123",
  "picture": "https://...",
  "phoneNumber": "9876543210",
  "aadharNumber": "123456789012",
  "drivingLicenseNumber": "DL12AB0012345",
  "isVerified": true,
  "isAvailble": true,
  "location": {
    "type": "Point",
    "coordinates": [77.1025, 28.7041]
  },
  "lastActiveAt": "2024-01-15T10:30:00Z"
}
```

#### Toggle Availability Status

**Endpoint:** `PATCH /api/rider/toggle`

**Authentication:** Required (rider role)

**Request Body:**

```json
{
  "isAvailble": true
}
```

**Response (200 OK):**

```json
{
  "message": "Rider availability updated",
  "isAvailble": true
}
```

### Order Management Endpoints

#### Accept Order

**Endpoint:** `POST /api/rider/accept/:orderId`

**Authentication:** Required (rider role)

**Path Parameters:**

```
orderId: "order123" (string, required)
```

**Response (200 OK):**

```json
{
  "message": "Order accepted successfully",
  "order": {
    "_id": "order123",
    "restaurantId": "rest123",
    "userId": "user123",
    "totalAmount": 550,
    "addressId": "addr123"
  }
}
```

#### Get Current Order

**Endpoint:** `GET /api/rider/order/current`

**Authentication:** Required (rider role)

**Response (200 OK):**

```json
{
  "order": {
    "_id": "order123",
    "userId": "user123",
    "restaurantId": "rest123",
    "totalAmount": 550,
    "status": "out_for_delivery",
    "items": [],
    "address": {}
  }
}
```

**Response (404 Not Found):**

```json
{
  "message": "No current order"
}
```

#### Update Order Status

**Endpoint:** `PUT /api/rider/order/update/:orderId`

**Authentication:** Required (rider role)

**Path Parameters:**

```
orderId: "order123" (string, required)
```

**Request Body:**

```json
{
  "status": "delivered",
  "latitude": 28.7041,
  "longitude": 77.1025
}
```

**Response (200 OK):**

```json
{
  "message": "Order status updated",
  "order": {
    "_id": "order123",
    "status": "delivered",
    "updatedAt": "2024-01-15T10:45:00Z"
  }
}
```

## Message Queue Integration

### RabbitMQ Queues

#### Order Ready Queue

- **Name:** `order_ready_queue`
- **Purpose:** Receives order ready events from restaurant service
- **Payload:**

```json
{
  "orderId": "order-123",
  "restaurantId": "restaurant-111",
  "readyAt": "2024-01-15T10:30:00Z"
}
```

- **Consumer Function:** `startOrderReadyConsumer()`
- **Action:** Assigns available riders to ready orders

#### Rider Queue

- **Name:** `rider_queue`
- **Purpose:** Publishes rider assignment events
- **Payload:**

```json
{
  "orderId": "order-123",
  "riderId": "rider-789",
  "acceptedAt": "2024-01-15T10:31:00Z"
}
```

## Business Logic

### Rider Profile Creation Flow

1. **Authentication Check**: Verify user is authenticated and has rider role
2. **File Upload**: Receive rider picture via Multer
3. **Image Processing**: Convert file to buffer using datauri
4. **Remote Upload**: POST image to Utils Service for storage
5. **Validation**: Check all required fields present
6. **Duplicate Check**: Verify no existing profile for user
7. **Profile Creation**: Create rider document in MongoDB
8. **Response**: Return created profile with verification status

### Order Acceptance Flow

1. **Rider Authentication**: Verify JWT and rider role
2. **Availability Check**: Confirm rider is available
3. **Order Validation**: Check order exists and is ready
4. **Order Assignment**: Assign rider to order
5. **Status Update**: Set order status to "out_for_delivery"
6. **Real-time Notification**: Emit event to customer via Realtime Service
7. **Consumer Update**: Publish to RabbitMQ rider queue
8. **Response**: Return accepted order details

### Order Status Update Flow

1. **Rider Authentication**: Verify JWT and rider role
2. **Current Order Check**: Verify this is rider's current order
3. **Status Validation**: Check valid status transition
4. **Location Update**: Store rider's current coordinates
5. **Database Update**: Update order status in MongoDB
6. **Real-time Notification**: Emit status update to customer
7. **Completion Check**: If delivered, mark rider as available again
8. **Response**: Return updated order

### Availability Status Flow

1. **Rider Authentication**: Verify JWT
2. **Current Order Check**: Verify no ongoing delivery
3. **Status Toggle**: Update isAvailble flag
4. **Activity Update**: Update lastActiveAt timestamp
5. **Real-time Notification**: Update rider availability in system
6. **Response**: Return updated status

## Error Handling

All endpoints implement comprehensive error handling with try-catch middleware.

### Common Error Responses

| Status | Error                                | Cause                            |
| ------ | ------------------------------------ | -------------------------------- |
| 400    | Rider Image is required              | No image uploaded                |
| 400    | All fields are required              | Missing required fields          |
| 400    | Rider profile already exists         | Profile already created for user |
| 401    | Unauthorized                         | Missing or invalid JWT           |
| 403    | Only riders can create rider profile | User doesn't have rider role     |
| 404    | Rider not found                      | Profile doesn't exist            |
| 404    | No current order                     | Rider has no active delivery     |
| 500    | Failed to generate image buffer      | Image processing error           |

## Development

### Run Development Server

```bash
npm run dev
```

This will start both TypeScript compiler in watch mode and the Node.js server with live reload.

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
docker build -t rider-service:latest .
```

Run container:

```bash
docker run -p 5005:5005 \
  -e PORT=5005 \
  -e MONGO_URI=mongodb://mongo:27017/zomato_clone \
  -e JWT_SEC=your-secret-key \
  -e RABBITMQ_URL=amqp://rabbitmq:5672 \
  -e UTILS_SERVICE=http://utils-service:5002 \
  -e REALTIME_SERVICE=http://realtime-service:5004 \
  -e RESTAURANT_SERVICE=http://restaurant-service:5001 \
  -e INTERNAL_SERVICE_KEY=your-internal-key \
  rider-service:latest
```

### Docker Compose

```yaml
rider-service:
  build: ./rider-service
  env_file:
    - ./rider-service/.env
  ports:
    - "5005:5005"
  depends_on:
    - mongodb
    - rabbitmq
  restart: unless-stopped
```

### Kubernetes Deployment

See the `food-delivery-k8s/` directory for Kubernetes manifests.

## Examples

### Example 1: Create Rider Profile

```bash
curl -X POST http://localhost:5005/api/rider/new \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "phoneNumber=9876543210" \
  -F "aadharNumber=123456789012" \
  -F "drivingLicenseNumber=DL12AB0012345" \
  -F "latitude=28.7041" \
  -F "longitude=77.1025" \
  -F "picture=@/path/to/photo.jpg"
```

### Example 2: Get Rider Profile

```bash
curl -X GET http://localhost:5005/api/rider/myprofile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Example 3: Toggle Availability

```bash
curl -X PATCH http://localhost:5005/api/rider/toggle \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "isAvailble": true
  }'
```

### Example 4: Accept Order

```bash
curl -X POST http://localhost:5005/api/rider/accept/order123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Example 5: Update Order Status

```bash
curl -X PUT http://localhost:5005/api/rider/order/update/order123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "delivered",
    "latitude": 28.7041,
    "longitude": 77.1025
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

### JWT Token Issues

**Error:** `Unauthorized` or `Invalid token`

**Solution:**

- Verify token is valid and not expired
- Check JWT_SEC matches other services
- Ensure token is in Authorization header

### Image Upload Failed

**Error:** `Failed to generate image buffer`

**Solution:**

- Verify file is a valid image format
- Check Utils Service is running
- Verify UTILS_SERVICE URL in .env

### Profile Already Exists

**Error:** `Rider profile already exists`

**Solution:**

- Each user can have only one rider profile
- Use GET /api/rider/myprofile to fetch existing profile
- Delete profile first if you need to recreate

## Integration with Other Services

### Utils Service

- **Purpose**: Image upload and storage
- **Endpoint**: `POST /api/upload`
- **Data**: Picture buffer for rider profile

### Realtime Service

- **Purpose**: Real-time notifications to customers
- **Events**: Order status updates, rider location updates
- **Protocol**: Socket.io emits via internal API

### Restaurant Service

- **Purpose**: Order information retrieval
- **Integration**: Query restaurant details for deliveries

### Auth Service

- **Purpose**: JWT token validation
- **Integration**: Token verification via isAuth middleware

## Performance Considerations

1. **Geospatial Queries**: Uses 2dsphere indexes for efficient location queries
2. **Connection Pooling**: MongoDB connection pooling configured
3. **Message Queue**: RabbitMQ ensures async order assignment
4. **Caching**: Consider Redis for frequently accessed rider data

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
