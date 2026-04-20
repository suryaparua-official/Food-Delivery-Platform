# Utils Service

The Utils Service is a utility microservice providing shared functionality for the food delivery platform. It handles file uploads, image optimization, payment processing integration with multiple payment gateways (Razorpay and Stripe), and manages payment events through message queues.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Payment Processing](#payment-processing)
- [File Upload](#file-upload)
- [Message Queue Integration](#message-queue-integration)
- [Error Handling](#error-handling)
- [Development](#development)
- [Deployment](#deployment)
- [Examples](#examples)
- [Payment Gateway Setup](#payment-gateway-setup)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

The Utils Service provides essential utility functions that multiple microservices rely on. It centralizes:

- **Image Upload & Storage**: Cloudinary integration for restaurant images, menu items, and rider photos
- **Payment Processing**: Dual payment gateway support (Razorpay for India, Stripe for international)
- **Payment Event Publishing**: RabbitMQ integration for async payment notifications
- **Buffer-to-URL Conversion**: Efficient image handling and CDN delivery

This service runs on **Port 5002** and integrates with Cloudinary for media storage, payment providers for transaction processing, and RabbitMQ for event-driven architecture.

## Features

- **Image Upload & Management**
  - Upload images to Cloudinary with automatic optimization
  - Support for restaurant photos, menu items, and rider profiles
  - Secure URL generation for CDN delivery
  - Buffer-based upload from other services
  - Automatic image transformation and compression

- **Razorpay Payment Integration**
  - Create payment orders
  - Verify payment signatures
  - Support for multiple payment methods (Cards, UPI, Wallets)
  - Webhook handling for payment notifications
  - Automatic payment verification

- **Stripe Payment Integration**
  - Create checkout sessions
  - Support for card payments
  - Hosted checkout experience
  - Webhook handling for payment events
  - Multi-currency support

- **Payment Event Management**
  - Publish payment success events to RabbitMQ
  - Async payment processing
  - Order status synchronization
  - Payment status tracking

- **Request Validation**
  - Order ID validation
  - Payment amount verification
  - Signature verification for webhook security

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js 5.x
- **Payment Gateways**: Razorpay 2.x, Stripe 20.x
- **Media Storage**: Cloudinary 2.x
- **Message Queue**: RabbitMQ with amqplib
- **HTTP Client**: Axios for inter-service communication
- **Utilities**: CORS, dotenv
- **Development**: Concurrently, TypeScript compiler

## Prerequisites

Before you begin, ensure you have:

- **Node.js** (v16.x or higher) - [Download](https://nodejs.org/)
- **npm** (v8.x or higher) - Comes with Node.js
- **Cloudinary Account** - [Sign up](https://cloudinary.com/users/register/free)
- **Razorpay Account** (for Indian payments) - [Sign up](https://razorpay.com/)
- **Stripe Account** (for international payments) - [Sign up](https://stripe.com/)
- **RabbitMQ** (for message queuing) - [Download](https://www.rabbitmq.com/download.html)
- **Git** - [Download](https://git-scm.com/)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/food-delivery-platform.git
cd services/backend/utils-service
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
PORT=5002

# Cloudinary Configuration
CLOUD_NAME=your_cloudinary_name
CLOUD_API_KEY=your_cloudinary_api_key
CLOUD_SECRET_KEY=your_cloudinary_secret_key

# Payment Gateways
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Frontend Configuration
FRONTEND_URL=http://localhost:5173

# External Services
RESTAURANT_SERVICE=http://localhost:5001
INTERNAL_SERVICE_KEY=your_internal_service_key

# Message Queue
RABBITMQ_URL=amqp://guest:guest@localhost:5672
PAYMENT_QUEUE=payment_event
```

**Environment Variables Explained:**

| Variable               | Description                        | Example                             |
| ---------------------- | ---------------------------------- | ----------------------------------- |
| `PORT`                 | Service listening port             | `5002`                              |
| `CLOUD_NAME`           | Cloudinary cloud name              | `your-cloud`                        |
| `CLOUD_API_KEY`        | Cloudinary API key                 | `123456789`                         |
| `CLOUD_SECRET_KEY`     | Cloudinary secret key              | `your-secret-key`                   |
| `STRIPE_SECRET_KEY`    | Stripe secret API key              | `sk_test_...`                       |
| `RAZORPAY_KEY_ID`      | Razorpay key ID                    | `rzp_test_...`                      |
| `RAZORPAY_KEY_SECRET`  | Razorpay key secret                | `your-secret`                       |
| `FRONTEND_URL`         | Frontend URL for payment redirects | `http://localhost:5173`             |
| `RESTAURANT_SERVICE`   | Restaurant service URL             | `http://localhost:5001`             |
| `INTERNAL_SERVICE_KEY` | Internal API authentication key    | `your-internal-key`                 |
| `RABBITMQ_URL`         | RabbitMQ connection string         | `amqp://guest:guest@localhost:5672` |
| `PAYMENT_QUEUE`        | Payment event queue name           | `payment_event`                     |

## Project Structure

```
utils-service/
├── src/
│   ├── config/
│   │   ├── razorpay.ts                # Razorpay configuration
│   │   ├── verifyRazorpay.ts          # Razorpay signature verification
│   │   ├── payment.producer.ts        # RabbitMQ payment publisher
│   │   └── rabbitmq.ts                # RabbitMQ connection setup
│   ├── controllers/
│   │   └── payment.ts                 # Payment processing logic
│   ├── routes/
│   │   ├── cloudinary.ts              # File upload routes
│   │   └── payment.ts                 # Payment routes
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

## API Endpoints

### File Upload Endpoints

#### Upload Image

**Endpoint:** `POST /api/upload`

**Headers:**

```
Content-Type: application/json
```

**Request Body:**

```json
{
  "buffer": "data:image/jpeg;base64,/9j/4AAQSkZJRg..." (string, required)
}
```

**Response (200 OK):**

```json
{
  "url": "https://res.cloudinary.com/your-cloud/image/upload/v1642345678/restaurant_12345.jpg"
}
```

**Common Use Cases:**

- Restaurant image uploads (from restaurant-service)
- Menu item image uploads (from restaurant-service)
- Rider profile pictures (from rider-service)
- User profile pictures (from auth-service)

**Error Response (500 Internal Server Error):**

```json
{
  "message": "File upload failed: Invalid image format"
}
```

### Payment Endpoints

#### Create Razorpay Order

**Endpoint:** `POST /api/payment/create`

**Headers:**

```
Content-Type: application/json
```

**Request Body:**

```json
{
  "orderId": "order123" (string, required)
}
```

**Response (200 OK):**

```json
{
  "razorpayOrderId": "order_FJXDXpBxZ2EPFL",
  "key": "rzp_test_1Aa00000000001"
}
```

**Process:**

1. Receives order ID from client
2. Fetches order amount from Restaurant Service
3. Creates Razorpay order with amount in paise
4. Returns order ID and public key for frontend

**Error Response (400 Bad Request):**

```json
{
  "message": "Order not found or invalid"
}
```

#### Verify Razorpay Payment

**Endpoint:** `POST /api/payment/verify`

**Headers:**

```
Content-Type: application/json
```

**Request Body:**

```json
{
  "razorpay_order_id": "order_FJXDXpBxZ2EPFL",
  "razorpay_payment_id": "pay_FJXDXsEqGfQd5c",
  "razorpay_signature": "9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a03",
  "orderId": "order123"
}
```

**Response (200 OK):**

```json
{
  "message": "Payment verified successfully"
}
```

**Process:**

1. Verifies Razorpay signature cryptographically
2. Confirms payment authenticity
3. Publishes payment success event to RabbitMQ
4. Updates order status in restaurant service

**Error Response (400 Bad Request):**

```json
{
  "message": "Payment verification failed"
}
```

#### Create Stripe Checkout Session

**Endpoint:** `POST /api/payment/stripe/create`

**Headers:**

```
Content-Type: application/json
```

**Request Body:**

```json
{
  "orderId": "order123" (string, required)
}
```

**Response (200 OK):**

```json
{
  "url": "https://checkout.stripe.com/pay/cs_test_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p"
}
```

**Process:**

1. Receives order ID
2. Fetches order amount from Restaurant Service
3. Creates Stripe checkout session
4. Returns Stripe hosted checkout URL

**Error Response (500 Internal Server Error):**

```json
{
  "message": "stripe payment failed"
}
```

#### Verify Stripe Payment

**Endpoint:** `POST /api/payment/stripe/verify`

**Headers:**

```
Content-Type: application/json
```

**Request Body:**

```json
{
  "sessionId": "cs_test_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p"
}
```

**Response (200 OK):**

```json
{
  "message": "Payment verified successfully"
}
```

**Process:**

1. Validates Stripe session ID
2. Retrieves session details from Stripe
3. Confirms payment status
4. Publishes payment success event

**Error Response (400 Bad Request):**

```json
{
  "message": "Invalid or failed session"
}
```

## Payment Processing

### Razorpay Payment Flow

```
Frontend Request
    ↓
POST /api/payment/create (with orderId)
    ↓
Fetch Order Amount from Restaurant Service
    ↓
Create Razorpay Order (amount in paise)
    ↓
Return Order ID + Public Key to Frontend
    ↓
Frontend opens Razorpay Checkout Modal
    ↓
User completes payment
    ↓
POST /api/payment/verify (with transaction details)
    ↓
Verify Signature cryptographically
    ↓
Publish to RabbitMQ (payment_event queue)
    ↓
Restaurant Service receives payment confirmation
    ↓
Update Order Status to "confirmed"
```

### Stripe Payment Flow

```
Frontend Request
    ↓
POST /api/payment/stripe/create (with orderId)
    ↓
Fetch Order Amount from Restaurant Service
    ↓
Create Stripe Checkout Session
    ↓
Return Checkout URL to Frontend
    ↓
Frontend redirects to Stripe hosted checkout
    ↓
User completes payment
    ↓
Stripe redirects to success URL
    ↓
Frontend verifies with POST /api/payment/stripe/verify
    ↓
Verify Session with Stripe
    ↓
Publish to RabbitMQ (payment_event queue)
    ↓
Restaurant Service receives payment confirmation
```

## File Upload

### Image Upload Process

**Request Format:**

```json
{
  "buffer": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}
```

**Upload Steps:**

1. Service receives base64 encoded image buffer
2. Sends to Cloudinary API
3. Cloudinary processes and optimizes image
4. Returns secure CDN URL
5. URL stored in database by calling service

**Cloudinary Transformations:**

- Automatic compression
- Format optimization (WebP for modern browsers)
- Responsive image sizing
- Secure HTTPS delivery
- Global CDN distribution

**Supported Formats:**

- JPEG, PNG, WebP, GIF
- Maximum file size: 50MB (configurable)

## Message Queue Integration

### RabbitMQ Queues

#### Payment Event Queue

- **Name:** `payment_event`
- **Purpose:** Publishes payment success events
- **Publisher:** Utils Service
- **Subscriber:** Restaurant Service
- **Payload:**

```json
{
  "orderId": "order-123",
  "paymentId": "pay_FJXDXsEqGfQd5c",
  "provider": "razorpay"
}
```

- **Purpose**: Notifies restaurant service that payment is verified
- **Action**: Restaurant service updates order status to "confirmed"

## Error Handling

All endpoints implement comprehensive error handling.

### Common Error Responses

| Status | Error                            | Cause                                     |
| ------ | -------------------------------- | ----------------------------------------- |
| 400    | Payment verification failed      | Invalid Razorpay signature                |
| 400    | Invalid or failed session        | Stripe session not found or expired       |
| 400    | Order not found                  | Order doesn't exist in restaurant service |
| 500    | stripe payment failed            | Error creating Stripe session             |
| 500    | File upload failed               | Error uploading to Cloudinary             |
| 500    | Cloudinary configuration missing | Missing environment variables             |

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
docker build -t utils-service:latest .
```

Run container:

```bash
docker run -p 5002:5002 \
  -e PORT=5002 \
  -e CLOUD_NAME=your-cloud \
  -e CLOUD_API_KEY=your-api-key \
  -e CLOUD_SECRET_KEY=your-secret-key \
  -e STRIPE_SECRET_KEY=sk_test_... \
  -e RAZORPAY_KEY_ID=rzp_test_... \
  -e RAZORPAY_KEY_SECRET=your-secret \
  -e RABBITMQ_URL=amqp://rabbitmq:5672 \
  -e RESTAURANT_SERVICE=http://restaurant-service:5001 \
  -e INTERNAL_SERVICE_KEY=your-internal-key \
  -e FRONTEND_URL=http://localhost:5173 \
  utils-service:latest
```

### Docker Compose

```yaml
utils-service:
  build: ./utils-service
  env_file:
    - ./utils-service/.env
  ports:
    - "5002:5002"
  depends_on:
    - rabbitmq
  restart: unless-stopped
```

### Kubernetes Deployment

See the `food-delivery-k8s/` directory for Kubernetes manifests.

## Examples

### Example 1: Upload Restaurant Image

```bash
# Convert image to base64
base64_image=$(base64 /path/to/image.jpg | tr -d '\n')

curl -X POST http://localhost:5002/api/upload \
  -H "Content-Type: application/json" \
  -d "{\"buffer\": \"data:image/jpeg;base64,$base64_image\"}"
```

### Example 2: Create Razorpay Order

```bash
curl -X POST http://localhost:5002/api/payment/create \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "order123"
  }'
```

### Example 3: Verify Razorpay Payment

```bash
curl -X POST http://localhost:5002/api/payment/verify \
  -H "Content-Type: application/json" \
  -d '{
    "razorpay_order_id": "order_FJXDXpBxZ2EPFL",
    "razorpay_payment_id": "pay_FJXDXsEqGfQd5c",
    "razorpay_signature": "9ef4dffbfd84f1318f6739a3ce19f9d85851857ae648f114332d8401e0949a03",
    "orderId": "order123"
  }'
```

### Example 4: Create Stripe Checkout

```bash
curl -X POST http://localhost:5002/api/payment/stripe/create \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": "order123"
  }'
```

## Payment Gateway Setup

### Razorpay Setup

#### Step 1: Create Razorpay Account

- Go to [Razorpay](https://razorpay.com/)
- Sign up for an account
- Complete KYC verification

#### Step 2: Get API Credentials

- Navigate to Settings → API Keys
- Copy Key ID and Key Secret
- Add to `.env` file

#### Step 3: Setup Webhooks (Optional)

- Go to Settings → Webhooks
- Add webhook URL: `https://your-domain/api/payment/webhook`
- Select events: `payment.authorized`, `payment.failed`

#### Step 4: Test Credentials

- Use test credentials for development
- Test cards: 4111 1111 1111 1111 (Success)
- Expiry: Any future date, CVV: Any 3 digits

### Stripe Setup

#### Step 1: Create Stripe Account

- Go to [Stripe](https://stripe.com/)
- Sign up for an account
- Verify email

#### Step 2: Get API Keys

- Navigate to Developers → API Keys
- Copy Secret Key
- Add to `.env` file

#### Step 3: Configure Webhooks

- Go to Developers → Webhooks
- Add endpoint: `https://your-domain/api/payment/webhook`
- Select events: `checkout.session.completed`

#### Step 4: Test Credentials

- Stripe automatically provides test mode keys
- Test card: 4242 4242 4242 4242
- Expiry: Any future date, CVC: Any 3 digits

## Troubleshooting

### Cloudinary Upload Failed

**Error:** `File upload failed: Invalid image format`

**Solution:**

- Verify image is in supported format (JPEG, PNG, WebP, GIF)
- Check file size doesn't exceed 50MB
- Verify Cloudinary credentials in .env
- Test Cloudinary connection: `npx cloudinary-cli config get`

### Razorpay Payment Verification Failed

**Error:** `Payment verification failed`

**Solution:**

- Verify Razorpay API credentials are correct
- Check signature verification logic
- Ensure order amount matches (note: Razorpay uses paise, multiply by 100)
- Verify timestamp hasn't expired (payment must be recent)

### Stripe Checkout Session Failed

**Error:** `stripe payment failed`

**Solution:**

- Verify Stripe secret key is correct
- Check FRONTEND_URL is accessible
- Ensure order ID is valid
- Test Stripe connection: `curl https://api.stripe.com/v1/account -u sk_test_YOUR_KEY:`

### Order Not Found Error

**Error:** `Order not found or invalid`

**Solution:**

- Verify Restaurant Service is running
- Check RESTAURANT_SERVICE URL in .env
- Verify INTERNAL_SERVICE_KEY matches restaurant service
- Ensure order exists in restaurant service database

### RabbitMQ Connection Failed

**Error:** `Connection refused`

**Solution:**

- Ensure RabbitMQ is running
- Check RABBITMQ_URL in .env
- Verify credentials are correct
- Check RabbitMQ management UI: `http://localhost:15672`

## Security Considerations

1. **API Keys**: Never commit .env file to repository
2. **Signature Verification**: Always verify payment signatures cryptographically
3. **HTTPS**: Use HTTPS in production for payment endpoints
4. **CORS**: Configure allowed origins in production
5. **Rate Limiting**: Implement rate limiting for payment endpoints
6. **Webhook Secrets**: Validate webhook signatures from payment providers

## Service Integration

### Restaurant Service

- **Purpose**: Fetch order details and amounts
- **Integration**: GET `/api/order/payment/:orderId`
- **Authentication**: Internal API key

### Payment Consumers

- **Service**: Restaurant Service
- **Queue**: `payment_event`
- **Action**: Updates order status to confirmed

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/your-feature`
5. Create a Pull Request

## License

This project is licensed under the ISC License.
