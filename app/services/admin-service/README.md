# Admin Service

The Admin Service is a critical microservice in the food delivery platform responsible for administrative operations, verification workflows, and platform management. It handles restaurant and rider verification, analytics, and administrative tasks.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Authentication](#authentication)
- [Error Handling](#error-handling)
- [Development](#development)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Overview

The Admin Service provides administrative capabilities for the food delivery platform, including:

- Verification of restaurants and delivery riders
- Monitoring pending applications
- Administrative user management
- Platform oversight and controls

This service runs on **Port 5006** and communicates with MongoDB for data persistence and other microservices through the Nginx API gateway.

## Features

- **Restaurant Verification**
  - View pending restaurant applications
  - Verify restaurants with validation
  - Track verification status and timestamps

- **Rider Verification**
  - View pending rider applications
  - Verify delivery partners
  - Manage rider verification status

- **Authentication & Authorization**
  - JWT-based authentication
  - Role-based access control (Admin role required)
  - Secure endpoint protection

- **Error Handling**
  - Comprehensive error messages
  - Invalid ID validation
  - Not found error handling

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js 5.x
- **Database**: MongoDB 7.x
- **Authentication**: JWT (jsonwebtoken 9.x)
- **Utilities**: CORS, dotenv
- **Development**: Concurrently for parallel processes, TypeScript compiler

## Prerequisites

Before you begin, ensure you have installed:

- **Node.js** (v16.x or higher) - [Download](https://nodejs.org/)
- **npm** (v8.x or higher) - Comes with Node.js
- **MongoDB** (local or Atlas) - [Download](https://www.mongodb.com/try/download/community)
- **Git** - [Download](https://git-scm.com/)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/food-delivery-platform.git
cd services/backend/admin-service
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
PORT=5006

# Database Configuration
MONGO_URI=mongodb://localhost:27017
DB_NAME=Zomato_Clone

# Authentication
JWT_SEC=your_jwt_secret_key_here_make_it_strong
```

**Environment Variables Explained:**

| Variable    | Description                       | Example                                       |
| ----------- | --------------------------------- | --------------------------------------------- |
| `PORT`      | Service listening port            | `5006`                                        |
| `MONGO_URI` | MongoDB connection string         | `mongodb+srv://user:pass@cluster.mongodb.net` |
| `DB_NAME`   | Database name                     | `Zomato_Clone`                                |
| `JWT_SEC`   | JWT secret for token verification | `your-secret-key-min-32-chars`                |

## Project Structure

```
admin-service/
├── src/
│   ├── config/
│   │   └── db.ts                 # MongoDB connection configuration
│   ├── controllers/
│   │   └── admin.ts              # Admin operation handlers
│   ├── middlewares/
│   │   ├── isAuth.ts             # Authentication & authorization middleware
│   │   └── trycatch.ts           # Error handling wrapper
│   ├── routes/
│   │   └── admin.ts              # Route definitions
│   ├── util/
│   │   └── collection.ts         # MongoDB collection getters
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

## API Endpoints

All endpoints require authentication. Use JWT token in the `Authorization` header:

```
Authorization: Bearer <jwt_token>
```

### Get Pending Restaurants

Retrieve all restaurants pending verification.

**Endpoint:** `GET /api/v1/admin/restaurant/pending`

**Headers:**

```
Authorization: Bearer <jwt_token>
```

**Permissions:** Admin role required

**Response (200 OK):**

```json
{
  "count": 2,
  "restaurants": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "name": "Pizza Palace",
      "email": "contact@pizzapalace.com",
      "isVerified": false,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Error Response (401 Unauthorized):**

```json
{
  "message": "Unauthorized"
}
```

### Get Pending Riders

Retrieve all riders pending verification.

**Endpoint:** `GET /api/v1/admin/rider/pending`

**Headers:**

```
Authorization: Bearer <jwt_token>
```

**Permissions:** Admin role required

**Response (200 OK):**

```json
{
  "count": 3,
  "riders": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "isVerified": false,
      "createdAt": "2024-01-14T14:20:00Z",
      "updatedAt": "2024-01-14T14:20:00Z"
    }
  ]
}
```

### Verify Restaurant

Approve and verify a pending restaurant.

**Endpoint:** `PATCH /api/v1/verify/restaurant/:id`

**Headers:**

```
Authorization: Bearer <jwt_token>
```

**URL Parameters:**

- `id` - MongoDB ObjectId of the restaurant

**Permissions:** Admin role required

**Response (200 OK):**

```json
{
  "message": "Restaurant verified successfully"
}
```

**Error Responses:**

- 400 Bad Request (Invalid ID):

```json
{
  "message": "Invalid object id"
}
```

- 404 Not Found:

```json
{
  "message": "Restaurant not found"
}
```

### Verify Rider

Approve and verify a pending rider.

**Endpoint:** `PATCH /api/v1/verify/rider/:id`

**Headers:**

```
Authorization: Bearer <jwt_token>
```

**URL Parameters:**

- `id` - MongoDB ObjectId of the rider

**Permissions:** Admin role required

**Response (200 OK):**

```json
{
  "message": "rider verified successfully"
}
```

**Error Responses:**

- 400 Bad Request (Invalid ID):

```json
{
  "message": "Invalid object id"
}
```

- 404 Not Found:

```json
{
  "message": "rider not found"
}
```

## Authentication

The Admin Service uses JWT (JSON Web Tokens) for authentication and role-based access control.

### Authentication Flow

1. User logs in via Auth Service and receives JWT token
2. Client includes JWT in `Authorization` header: `Bearer <token>`
3. Admin Service middleware verifies token and extracts user info
4. Middleware checks if user has admin role
5. If valid, request proceeds; otherwise, returns 401 Unauthorized

### Required Claims in JWT

The JWT token must contain:

```json
{
  "userId": "...",
  "email": "...",
  "role": "admin"
}
```

### Middleware

**`isAuth`** - Verifies JWT token and authorization

- Extracts token from Authorization header
- Verifies token signature
- Extracts user information
- Allows endpoint to access user data via `req.user`

**`isAdmin`** - Checks for admin role

- Ensures user has admin role
- Returns 403 Forbidden if not admin

## Error Handling

The service implements comprehensive error handling with custom middleware:

### TryCatch Wrapper

All controller functions use the `TryCatch` wrapper that:

- Catches exceptions automatically
- Prevents server crashes
- Returns consistent error responses
- Logs errors for debugging

### Common Error Responses

| Status | Error             | Cause                                |
| ------ | ----------------- | ------------------------------------ |
| 400    | Invalid object id | Malformed MongoDB ObjectId           |
| 401    | Unauthorized      | Missing or invalid JWT token         |
| 403    | Forbidden         | Insufficient permissions (not admin) |
| 404    | Not found         | Resource doesn't exist               |
| 500    | Server error      | Unexpected exception                 |

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
docker build -t admin-service:latest .
```

Run container:

```bash
docker run -p 5006:5006 \
  -e PORT=5006 \
  -e MONGO_URI=mongodb://mongo:27017 \
  -e DB_NAME=Zomato_Clone \
  -e JWT_SEC=your-secret-key \
  admin-service:latest
```

### Kubernetes Deployment

See the `food-delivery-k8s/` directory for Kubernetes manifests and deployment using ArgoCD.

### Environment Setup

Ensure MongoDB is accessible and all environment variables are set correctly before deployment.

## Code Conventions

- **TypeScript**: Strict mode enabled
- **Module System**: ES modules (ESM)
- **Error Handling**: Async/await with try-catch
- **Naming**: camelCase for variables, PascalCase for classes
- **File Organization**: Feature-based structure

## Security Considerations

1. **JWT Secret**: Use a strong, random string (minimum 32 characters)
2. **CORS**: Configure allowed origins in production
3. **MongoDB**: Use connection strings with authentication
4. **Environment Variables**: Never commit `.env` file
5. **Input Validation**: All IDs are validated before database queries

## Troubleshooting

### MongoDB Connection Error

**Error:** `connect ECONNREFUSED`

**Solution:**

- Ensure MongoDB is running locally or verify Atlas connection string
- Check `MONGO_URI` in `.env` file

### JWT Token Errors

**Error:** `Invalid token` or `Token expired`

**Solution:**

- Verify token is correctly sent in Authorization header
- Check JWT_SEC matches the Auth Service
- Ensure token hasn't expired

### Port Already in Use

**Error:** `EADDRINUSE: address already in use :::5006`

**Solution:**

```bash
# Find process using port 5006
lsof -i :5006

# Kill process
kill -9 <PID>
```

## Testing API Endpoints

Use cURL, Postman, or similar tools to test:

```bash
# Get pending restaurants (replace TOKEN with actual JWT)
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:5006/api/v1/admin/restaurant/pending

# Verify restaurant (replace ID with actual MongoDB ObjectId)
curl -X PATCH \
  -H "Authorization: Bearer TOKEN" \
  http://localhost:5006/api/v1/verify/restaurant/507f1f77bcf86cd799439011
```

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/your-feature`
5. Create a Pull Request

## License

This project is licensed under the ISC License.
