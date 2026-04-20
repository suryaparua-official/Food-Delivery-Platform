# Auth Service

The Auth Service is the core authentication and authorization microservice in the food delivery platform. It handles user authentication via Google OAuth, role management, JWT token generation, and user profile management.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Project Structure](#project-structure)
- [Authentication Flow](#authentication-flow)
- [API Endpoints](#api-endpoints)
- [User Roles](#user-roles)
- [Error Handling](#error-handling)
- [Development](#development)
- [Deployment](#deployment)
- [Google OAuth Setup](#google-oauth-setup)
- [Contributing](#contributing)
- [License](#license)

## Overview

The Auth Service provides secure authentication and authorization for the entire food delivery platform. It integrates Google OAuth for seamless login, manages user profiles, assigns user roles, and generates JWT tokens for subsequent API calls.

This service runs on **Port 5000** and uses Mongoose/MongoDB for data persistence. It communicates with the frontend via REST API and with other microservices through JWT tokens.

## Features

- **Google OAuth Authentication**
  - Seamless Google Sign-In integration
  - Automatic user creation on first login
  - Secure token exchange and validation

- **User Management**
  - User profile creation and retrieval
  - User information persistence
  - Profile image storage

- **Role-Based Access Control**
  - Support for multiple user roles (customer, rider, seller)
  - Role assignment after authentication
  - Role-based authorization for other services

- **JWT Token Management**
  - Secure JWT token generation
  - 7-day token expiration
  - Token refresh capability

- **User Profile API**
  - Retrieve current user profile
  - Access user information via authenticated endpoints
  - User data validation

## Tech Stack

- **Runtime**: Node.js with TypeScript
- **Framework**: Express.js 5.x
- **Database**: MongoDB with Mongoose 9.x
- **Authentication**:
  - Google OAuth2
  - JWT (jsonwebtoken 9.x)
- **HTTP Client**: Axios for Google API calls
- **Utilities**: CORS, dotenv
- **Development**: Concurrently, TypeScript compiler

## Prerequisites

Before you begin, ensure you have installed:

- **Node.js** (v16.x or higher) - [Download](https://nodejs.org/)
- **npm** (v8.x or higher) - Comes with Node.js
- **MongoDB** (local or Atlas) - [Download](https://www.mongodb.com/try/download/community)
- **Git** - [Download](https://git-scm.com/)
- **Google OAuth Credentials** - [Setup Guide](#google-oauth-setup)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/food-delivery-platform.git
cd services/backend/auth-service
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
PORT=5000

# Database Configuration
MONGO_URI=mongodb://localhost:27017/zomato_clone

# Authentication
JWT_SEC=your_jwt_secret_key_here_make_it_strong_min_32_chars

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

**Environment Variables Explained:**

| Variable               | Description                  | Example                                                    |
| ---------------------- | ---------------------------- | ---------------------------------------------------------- |
| `PORT`                 | Service listening port       | `5000`                                                     |
| `MONGO_URI`            | MongoDB connection string    | `mongodb+srv://user:pass@cluster.mongodb.net/zomato_clone` |
| `JWT_SEC`              | JWT secret for token signing | `your-super-secret-key-min-32-characters`                  |
| `GOOGLE_CLIENT_ID`     | Google OAuth Client ID       | `xxx-yyy.apps.googleusercontent.com`                       |
| `GOOGLE_CLIENT_SECRET` | Google OAuth Client Secret   | `GOCSPX-xxxxxx`                                            |

## Project Structure

```
auth-service/
├── src/
│   ├── config/
│   │   ├── db.ts                 # MongoDB/Mongoose connection
│   │   └── googleConfig.ts       # Google OAuth configuration
│   ├── controllers/
│   │   └── auth.ts              # Authentication handlers
│   ├── middlewares/
│   │   ├── isAuth.ts            # JWT verification middleware
│   │   └── trycatch.ts          # Error handling wrapper
│   ├── model/
│   │   └── User.ts              # Mongoose User schema
│   ├── routes/
│   │   └── auth.ts              # Route definitions
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

## Authentication Flow

### Login Flow with Google OAuth

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT-SIDE FLOW                         │
│  Frontend → Google → Google OAuth Code → Auth Service       │
└─────────────────────────────────────────────────────────────┘

1. User clicks "Sign in with Google" on frontend
2. Google OAuth window opens
3. User authenticates with Google
4. Google returns authorization code
5. Frontend sends code to Auth Service (/api/auth/login)

┌─────────────────────────────────────────────────────────────┐
│                  SERVER-SIDE FLOW                           │
│     Auth Service → Google → User Info → Verify/Create User  │
└─────────────────────────────────────────────────────────────┘

6. Auth Service receives authorization code
7. Service exchanges code for Google access token
8. Service fetches user info from Google (email, name, picture)
9. Service checks if user exists in MongoDB
10. If not exists: Create new user
11. If exists: Use existing user
12. Generate JWT token with user data
13. Return token and user profile to client

14. Client stores JWT token
15. Client includes token in Authorization header for future requests
```

### Role Assignment Flow

```
1. After login, user profile page
2. User selects role (customer/rider/seller)
3. Frontend sends POST to /api/auth/add/role with role
4. Auth Service verifies JWT token
5. Service updates user role in MongoDB
6. Service generates new JWT with updated user data
7. Return new token and updated user to client
```

## API Endpoints

### 1. Login with Google OAuth

Authenticate user via Google OAuth.

**Endpoint:** `POST /api/auth/login`

**Request Body:**

```json
{
  "code": "authorization_code_from_google"
}
```

**Response (200 OK):**

```json
{
  "message": "Logged Success",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "image": "https://lh3.googleusercontent.com/...",
    "role": null,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:00Z"
  }
}
```

**Error Response (400 Bad Request):**

```json
{
  "message": "Authorization code is required"
}
```

### 2. Add/Update User Role

Assign or update user role after login.

**Endpoint:** `PUT /api/auth/add/role`

**Headers:**

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "role": "customer"
}
```

**Valid Roles:** `customer`, `rider`, `seller`

**Response (200 OK):**

```json
{
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "image": "https://lh3.googleusercontent.com/...",
    "role": "customer",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:01Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Responses:**

- 400 Bad Request (Invalid role):

```json
{
  "message": "Invalid role"
}
```

- 401 Unauthorized (Missing token):

```json
{
  "message": "Unauthorized"
}
```

- 404 Not Found:

```json
{
  "message": "User not found"
}
```

### 3. Get Current User Profile

Retrieve authenticated user's profile information.

**Endpoint:** `GET /api/auth/me`

**Headers:**

```
Authorization: Bearer <jwt_token>
```

**Response (200 OK):**

```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "John Doe",
  "email": "john@example.com",
  "image": "https://lh3.googleusercontent.com/...",
  "role": "customer",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:01Z"
}
```

**Error Response (401 Unauthorized):**

```json
{
  "message": "Unauthorized"
}
```

## User Roles

The platform supports three user roles:

### 1. Customer (customer)

- Browse restaurants
- Place food orders
- Track deliveries
- Manage account and addresses
- View order history

### 2. Rider (rider)

- Accept delivery orders
- Track and optimize delivery routes
- Manage delivery history
- View earnings and performance stats

### 3. Seller (seller)

- Manage restaurant profile
- Add/edit menu items
- View incoming orders
- Monitor restaurant analytics

**Note:** Users start with `role: null` after Google login and must select a role via the role assignment endpoint.

## User Model Schema

```typescript
{
  name: String (required),        // User's full name from Google
  email: String (required, unique), // User's email
  image: String (required),       // Profile picture URL from Google
  role: String (default: null),   // customer, rider, or seller
  createdAt: Date,                // Account creation timestamp
  updatedAt: Date                 // Last update timestamp
}
```

## JWT Token Structure

The JWT token contains the following payload:

```json
{
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "John Doe",
    "email": "john@example.com",
    "image": "https://lh3.googleusercontent.com/...",
    "role": "customer",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-15T10:30:01Z"
  },
  "iat": 1705306200, // Issued at
  "exp": 1705911000 // Expires in (7 days)
}
```

## Error Handling

The service implements comprehensive error handling with custom middleware:

### TryCatch Wrapper

All controller functions use the `TryCatch` wrapper that:

- Catches exceptions automatically
- Prevents server crashes
- Returns consistent error responses
- Logs errors for debugging

### Common Error Responses

| Status | Error                          | Cause                          |
| ------ | ------------------------------ | ------------------------------ |
| 400    | Invalid role                   | Role not in allowed list       |
| 400    | Authorization code is required | Missing code in login request  |
| 401    | Unauthorized                   | Missing or invalid JWT token   |
| 404    | User not found                 | User doesn't exist in database |
| 500    | Server error                   | Unexpected exception           |

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
docker build -t auth-service:latest .
```

Run container:

```bash
docker run -p 5000:5000 \
  -e PORT=5000 \
  -e MONGO_URI=mongodb://mongo:27017/zomato_clone \
  -e JWT_SEC=your-secret-key \
  -e GOOGLE_CLIENT_ID=your-client-id \
  -e GOOGLE_CLIENT_SECRET=your-client-secret \
  auth-service:latest
```

### Docker Compose

```yaml
auth-service:
  build: ./auth-service
  env_file:
    - ./auth-service/.env
  ports:
    - "5000:5000"
  depends_on:
    - mongodb
  restart: unless-stopped
```

### Kubernetes Deployment

See the `food-delivery-k8s/` directory for Kubernetes manifests and deployment using ArgoCD.

## Google OAuth Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Name it "Food Delivery Platform" (or your preferred name)

### Step 2: Enable Google OAuth API

1. In Google Cloud Console, go to "APIs & Services"
2. Click "Enable APIs and Services"
3. Search for "Google+ API"
4. Click "Enable"

### Step 3: Create OAuth 2.0 Credentials

1. Go to "Credentials" tab
2. Click "Create Credentials" → "OAuth 2.0 Client ID"
3. Choose "Web application"
4. Add Authorized redirect URIs:
   - `http://localhost:3000` (frontend dev)
   - `http://localhost:5000` (auth service)
   - Your production domain

### Step 4: Copy Credentials

1. Copy your **Client ID** and **Client Secret**
2. Add them to your `.env` file:
   ```env
   GOOGLE_CLIENT_ID=your_client_id
   GOOGLE_CLIENT_SECRET=your_client_secret
   ```

### Step 5: Frontend Configuration

In your frontend, configure Google OAuth with the same Client ID:

```javascript
// React Google OAuth component
<GoogleOAuthProvider clientId={process.env.VITE_GOOGLE_CLIENT_ID}>
  <GoogleLogin onSuccess={handleLoginSuccess} onError={handleLoginError} />
</GoogleOAuthProvider>
```

## Testing API Endpoints

Use cURL, Postman, or similar tools:

### Test Login (requires actual Google code)

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"code":"google_authorization_code"}'
```

### Test Get Profile

```bash
curl -X GET http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Test Add Role

```bash
curl -X PUT http://localhost:5000/api/auth/add/role \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role":"customer"}'
```

## Troubleshooting

### MongoDB Connection Error

**Error:** `connect ECONNREFUSED`

**Solution:**

- Ensure MongoDB is running
- Check `MONGO_URI` in `.env` file
- For Atlas: verify IP whitelist includes your IP

### JWT Token Errors

**Error:** `invalid token` or `jwt malformed`

**Solution:**

- Verify `JWT_SEC` matches between services
- Ensure token is properly formatted in Authorization header
- Check token hasn't expired (7-day expiration)

### Google OAuth Errors

**Error:** `invalid_client` or `redirect_uri_mismatch`

**Solution:**

- Verify Client ID and Client Secret are correct
- Check redirect URI matches Google Cloud Console settings
- Ensure `postmessage` is configured in OAuth2 client

### Port Already in Use

**Error:** `EADDRINUSE: address already in use :::5000`

**Solution:**

```bash
# Find process using port 5000
lsof -i :5000

# Kill process
kill -9 <PID>
```

## Security Considerations

1. **JWT Secret**: Use a strong, random string (minimum 32 characters)
2. **Google Credentials**: Never commit `.env` file to repository
3. **HTTPS**: Use HTTPS in production
4. **CORS**: Configure allowed origins appropriately
5. **Token Expiration**: 7-day expiration provides security-usability balance
6. **MongoDB**: Use connection strings with authentication

## Code Conventions

- **TypeScript**: Strict mode enabled
- **Module System**: ES modules (ESM)
- **Error Handling**: Async/await with try-catch
- **Naming**: camelCase for variables, PascalCase for classes
- **File Organization**: Feature-based structure

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Commit: `git commit -am 'Add feature'`
4. Push: `git push origin feature/your-feature`
5. Create a Pull Request

## License

This project is licensed under the ISC License.
