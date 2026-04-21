# Realtime Service

The Realtime Service is a WebSocket-based microservice that enables real-time communication between clients and servers in the food delivery platform. It handles live order updates, delivery tracking, status notifications, and real-time event streaming using Socket.io.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Socket Events](#socket-events)
- [Room System](#room-system)
- [Internal API](#internal-api)
- [Client Integration](#client-integration)
- [Authentication](#authentication)
- [Development](#development)
- [Deployment](#deployment)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

The Realtime Service provides WebSocket connectivity for the food delivery platform, enabling:

- Live order status updates
- Real-time delivery tracking
- Instant notifications
- Bidirectional client-server communication
- Room-based event broadcasting

This service runs on **Port 5004** and acts as a bridge between clients and backend services. It authenticates users via JWT tokens and manages separate communication rooms for users and restaurants.

## Features

- **Real-time Communication**
  - WebSocket connections via Socket.io
  - Low-latency event delivery
  - Automatic reconnection handling

- **Room-Based Broadcasting**
  - User-specific rooms (user:userId)
  - Restaurant-specific rooms (restaurant:restaurantId)
  - Selective event targeting

- **JWT Authentication**
  - Token verification on connection
  - User identification and validation
  - Secure WebSocket handshake

- **Internal Event Emission**
  - Backend services can emit events via REST API
  - Service-to-client communication
  - Event payload flexibility

- **Real-time Updates**
  - Order status changes
  - Delivery location updates
  - Restaurant notifications
  - System announcements

## Tech Stack

- **WebSocket Framework**: Socket.io 4.8.x
- **Runtime**: Node.js with TypeScript
- **HTTP Server**: Express.js 5.x
- **Authentication**: JWT (jsonwebtoken 9.x)
- **Utilities**: CORS, dotenv
- **Development**: Concurrently, TypeScript compiler

## Prerequisites

Before you begin, ensure you have installed:

- **Node.js** (v16.x or higher) - [Download](https://nodejs.org/)
- **npm** (v8.x or higher) - Comes with Node.js
- **Git** - [Download](https://git-scm.com/)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/food-delivery-platform.git
cd services/backend/realtime-service
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
PORT=5004

# Authentication
JWT_SEC=your_jwt_secret_key_here_make_it_strong

# Internal Service Communication
INTERNAL_SERVICE_KEY=your_internal_service_key_here
```

**Environment Variables Explained:**

| Variable               | Description                       | Example                 |
| ---------------------- | --------------------------------- | ----------------------- |
| `PORT`                 | Service listening port            | `5004`                  |
| `JWT_SEC`              | JWT secret for token verification | `your-super-secret-key` |
| `INTERNAL_SERVICE_KEY` | Internal API authentication key   | `your-internal-key-xyz` |

## Project Structure

```
realtime-service/
├── src/
│   ├── routes/
│   │   └── internal.ts          # Internal REST API routes
│   ├── socket.ts                # Socket.io initialization & handlers
│   └── index.ts                 # Application entry point
├── dist/                        # Compiled JavaScript (generated)
├── .env                         # Environment variables (not in repo)
├── .env.example                 # Environment template
├── .gitignore                   # Git ignore rules
├── Dockerfile                   # Docker configuration
├── package.json                 # Project dependencies
├── tsconfig.json                # TypeScript configuration
└── README.md                    # This file
```

## Architecture

### Connection Flow

```
┌─────────────────┐
│  Client/Browser │
└────────┬────────┘
         │
    WebSocket
    (with JWT)
         │
         ▼
┌─────────────────────────────────────────┐
│     Realtime Service (Port 5004)        │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Socket.io Server               │   │
│  │  - Authenticate JWT             │   │
│  │  - Join user rooms              │   │
│  │  - Join restaurant rooms        │   │
│  │  - Listen for events            │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  Internal REST API              │   │
│  │  - Emit events to rooms         │   │
│  │  - Service-to-service comm      │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
         │              │
    Events             REST
    (emit)             (POST)
         │              │
    ┌────▼──────────────▼────┐
    │  Backend Services      │
    │  (Auth, Restaurant,    │
    │   Rider, Order, etc.)  │
    └───────────────────────┘
```

## Socket Events

### Client-Side Events (Received)

These are events that clients listen for from the server:

#### Order Status Update

```javascript
socket.on("order:status_updated", (data) => {
  // data = { orderId, status, updatedAt, message }
});
```

#### Delivery Location Update

```javascript
socket.on("rider:location_updated", (data) => {
  // data = { riderId, latitude, longitude, timestamp }
});
```

#### Order Notification

```javascript
socket.on("notification:order", (data) => {
  // data = { message, type, orderId, severity }
});
```

#### Restaurant Notification

```javascript
socket.on("notification:restaurant", (data) => {
  // data = { message, type, restaurantId }
});
```

#### System Announcement

```javascript
socket.on("announcement:system", (data) => {
  // data = { message, type, priority }
});
```

### Server-Side Events (Emitted)

Events that the Realtime Service emits to clients via the internal API.

## Room System

The Realtime Service uses a room-based architecture for targeted message delivery:

### User Room

```
Format: user:{userId}

Purpose:
- Order status updates for specific user
- Personal notifications
- Account-related events

Example: user:507f1f77bcf86cd799439011
```

### Restaurant Room

```
Format: restaurant:{restaurantId}

Purpose:
- New orders for restaurant
- Restaurant-specific notifications
- Menu/profile update alerts

Example: restaurant:507f1f77bcf86cd799439012
```

### Broadcasting to Rooms

```javascript
// Send to specific user
io.to("user:userId").emit("notification:order", { message: "..." });

// Send to specific restaurant
io.to("restaurant:restaurantId").emit("order:new", { orderId: "..." });

// Send to all connected clients
io.emit("announcement:system", { message: "..." });
```

## Internal API

The Realtime Service exposes an internal REST API for backend services to emit events.

### Emit Event Endpoint

Allows backend services to emit events to connected clients via HTTP.

**Endpoint:** `POST /api/v1/internal/emit`

**Headers:**

```
Content-Type: application/json
x-internal-key: <INTERNAL_SERVICE_KEY>
```

**Request Body:**

```json
{
  "event": "order:status_updated",
  "room": "user:507f1f77bcf86cd799439011",
  "payload": {
    "orderId": "order-123",
    "status": "confirmed",
    "estimatedTime": 25,
    "updatedAt": "2024-01-15T10:30:00Z"
  }
}
```

**Parameters:**

| Parameter | Type   | Required | Description                            |
| --------- | ------ | -------- | -------------------------------------- |
| `event`   | string | Yes      | Event name to emit                     |
| `room`    | string | Yes      | Target room (user:id or restaurant:id) |
| `payload` | object | No       | Event data payload                     |

**Response (200 OK):**

```json
{
  "success": true
}
```

**Error Responses:**

- 400 Bad Request (Missing required fields):

```json
{
  "message": "event and room are required"
}
```

- 403 Forbidden (Invalid API key):

```json
{
  "message": "Forbidden"
}
```

### Example: Emit Order Update

```bash
curl -X POST http://localhost:5004/api/v1/internal/emit \
  -H "Content-Type: application/json" \
  -H "x-internal-key: your_internal_service_key" \
  -d '{
    "event": "order:status_updated",
    "room": "user:507f1f77bcf86cd799439011",
    "payload": {
      "orderId": "order-123",
      "status": "confirmed",
      "message": "Your order has been confirmed"
    }
  }'
```

## Client Integration

### React/Frontend Example

#### Installation

```bash
npm install socket.io-client
```

#### Connection Setup

```typescript
import { useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';

interface SocketContextType {
  socket: Socket | null;
  isConnected: boolean;
}

export const SocketContext = createContext<SocketContextType>({
  socket: null,
  isConnected: false,
});

export const SocketProvider = ({ children, token }) => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    if (!token) return;

    const newSocket = io('http://localhost:5004', {
      auth: {
        token: token,
      },
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      reconnectionAttempts: 5,
    });

    newSocket.on('connect', () => {
      console.log('Connected to Realtime Service');
      setIsConnected(true);
    });

    newSocket.on('disconnect', () => {
      console.log('Disconnected from Realtime Service');
      setIsConnected(false);
    });

    newSocket.on('connect_error', (error) => {
      console.error('Connection error:', error);
    });

    setSocket(newSocket);

    return () => {
      newSocket.close();
    };
  }, [token]);

  return (
    <SocketContext.Provider value={{ socket, isConnected }}>
      {children}
    </SocketContext.Provider>
  );
};
```

#### Listening to Events

```typescript
import { useContext, useEffect } from "react";
import { SocketContext } from "./SocketContext";
import toast from "react-hot-toast";

export const useOrderUpdates = () => {
  const { socket } = useContext(SocketContext);

  useEffect(() => {
    if (!socket) return;

    socket.on("order:status_updated", (data) => {
      console.log("Order updated:", data);
      toast.success(`Order ${data.orderId} is ${data.status}`);
    });

    socket.on("notification:order", (data) => {
      console.log("Order notification:", data);
      toast(data.message);
    });

    return () => {
      socket.off("order:status_updated");
      socket.off("notification:order");
    };
  }, [socket]);
};
```

## Authentication

### WebSocket Authentication Flow

1. Client connects to WebSocket with JWT token in auth headers
2. Server middleware verifies JWT token
3. Server decodes token and extracts user information
4. Server joins user to appropriate rooms based on user role
5. If authentication fails, connection is rejected

### JWT Token Requirements

The JWT token must contain user information:

```json
{
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "restaurantId": null
  },
  "iat": 1705306200,
  "exp": 1705911000
}
```

### Authentication Error Handling

```javascript
socket.on("connect_error", (error) => {
  if (error.message === "Unauthorized") {
    console.log("Authentication failed - Invalid token");
    // Redirect to login
  }
});
```

## Development

### Run Development Server

Start in development mode with file watching:

```bash
npm run dev
```

This command:

- Compiles TypeScript in watch mode
- Restarts Node.js on file changes
- Uses concurrently for parallel processes

### Build for Production

Compile TypeScript to JavaScript:

```bash
npm run build
```

Output will be in the `dist/` directory.

### Start Production Server

```bash
npm start
```

## Deployment

### Docker Deployment

Build Docker image:

```bash
docker build -t realtime-service:latest .
```

Run container:

```bash
docker run -p 5004:5004 \
  -e PORT=5004 \
  -e JWT_SEC=your-secret-key \
  -e INTERNAL_SERVICE_KEY=your-internal-key \
  realtime-service:latest
```

### Docker Compose

```yaml
realtime-service:
  build: ./realtime-service
  env_file:
    - ./realtime-service/.env
  ports:
    - "5004:5004"
  restart: unless-stopped
```

### Kubernetes Deployment

See the `food-delivery-k8s/` directory for Kubernetes manifests and deployment using ArgoCD.

## Examples

### Example 1: Order Status Update

When Order Service updates an order, it emits an event:

**Order Service (Backend):**

```javascript
// Order status changes to 'confirmed'
axios.post(
  "http://localhost:5004/api/v1/internal/emit",
  {
    event: "order:status_updated",
    room: `user:${userId}`,
    payload: {
      orderId: "order-123",
      status: "confirmed",
      estimatedTime: 25,
      message: "Your order has been confirmed",
    },
  },
  {
    headers: { "x-internal-key": INTERNAL_SERVICE_KEY },
  },
);
```

**Frontend (Client):**

```javascript
socket.on("order:status_updated", (data) => {
  // Update UI with new order status
  updateOrderUI(data.orderId, data.status);
  showNotification(data.message);
});
```

### Example 2: Delivery Location Update

Rider updates their location, multiple users receive updates:

**Rider Service (Backend):**

```javascript
// For each user with this order
axios.post("http://localhost:5004/api/v1/internal/emit", {
  event: "rider:location_updated",
  room: `user:${userId}`,
  payload: {
    riderId: "rider-456",
    latitude: 28.7041,
    longitude: 77.1025,
    timestamp: new Date(),
  },
});
```

**Frontend (Client):**

```javascript
socket.on("rider:location_updated", (data) => {
  // Update map with rider location
  updateRiderMarker(data.riderId, {
    lat: data.latitude,
    lng: data.longitude,
  });
});
```

### Example 3: Restaurant Notification

New order arrives at restaurant:

**Order Service (Backend):**

```javascript
axios.post("http://localhost:5004/api/v1/internal/emit", {
  event: "notification:restaurant",
  room: `restaurant:${restaurantId}`,
  payload: {
    message: "New order received",
    orderId: "order-789",
    totalAmount: 450,
  },
});
```

**Frontend (Restaurant Dashboard):**

```javascript
socket.on("notification:restaurant", (data) => {
  // Show new order alert
  showNotificationAlert(data.message);
  addOrderToQueue(data.orderId);
  playNotificationSound();
});
```

## Troubleshooting

### Connection Refused

**Error:** `ECONNREFUSED 127.0.0.1:5004`

**Solution:**

- Ensure the Realtime Service is running: `npm run dev`
- Check PORT is set correctly in `.env`
- Verify firewall allows port 5004

### Authentication Failed

**Error:** `connect_error: Unauthorized`

**Solution:**

- Verify JWT token is valid and not expired
- Check JWT_SEC matches between Auth Service and Realtime Service
- Ensure token is passed in auth headers during connection

### Events Not Received

**Error:** Events emitted but not received by client

**Solution:**

- Verify client is connected (check isConnected flag)
- Confirm room name is correct (user:userId format)
- Check browser console for Socket.io errors
- Verify event name matches on both sides

### CORS Errors

**Error:** `CORS policy: Cross-origin request blocked`

**Solution:**

- In development, CORS is set to "\*" - should work for all origins
- In production, update CORS origin in socket.ts:
  ```typescript
  cors: {
    origin: "https://yourdomain.com";
  }
  ```

### Port Already in Use

**Error:** `EADDRINUSE: address already in use :::5004`

**Solution:**

```bash
# Find process using port 5004
lsof -i :5004

# Kill process
kill -9 <PID>

# Or use different port
PORT=5005 npm run dev
```

## Real-time Events Reference

### Common Event Names

```
# Order Events
order:created
order:confirmed
order:preparing
order:ready_for_pickup
order:out_for_delivery
order:delivered
order:cancelled
order:status_updated

# Rider Events
rider:assigned
rider:location_updated
rider:arrived
rider:picked_up
rider:completed

# Notification Events
notification:order
notification:restaurant
notification:rider
notification:system

# Announcement Events
announcement:system
announcement:maintenance
announcement:promo
```

## Security Considerations

1. **JWT Secret**: Use a strong, random string for JWT_SEC
2. **Internal API Key**: Use a strong, random key for INTERNAL_SERVICE_KEY
3. **CORS**: In production, set specific allowed origins
4. **Token Expiration**: Implement token refresh mechanism on clients
5. **Rate Limiting**: Consider adding rate limiting for internal API
6. **Input Validation**: Validate room and event names on server

## Code Conventions

- **TypeScript**: Strict mode enabled
- **Module System**: ES modules (ESM)
- **Naming**: camelCase for variables, PascalCase for classes
- **Socket Events**: kebab-case (order:status_updated)
- **Rooms**: Format: `type:id` (user:123, restaurant:456)

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/your-feature`
5. Create a Pull Request

## License

This project is licensed under the ISC License.
