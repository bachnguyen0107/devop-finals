# Project Architecture

## System Overview

This is a Product Management API with a web UI built using Node.js + Express, designed for DevOps deployment and operations.

```
┌─────────────────────────────────────────┐
│         Web Browser (UI)                │
│   http://localhost:3000/               │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│      Express.js Application             │
│  ├─ Routes (API + UI)                   │
│  ├─ Controllers (Business Logic)        │
│  ├─ Validators (Input Validation)       │
│  └─ Services (Data Layer)               │
└────────────┬────────────────────────────┘
             │
      ┌──────┴──────┐
      │             │
┌─────▼──────┐   ┌──▼──────────────┐
│ MongoDB    │   │ In-Memory Store │
│ (Primary)  │   │ (Fallback)      │
└────────────┘   └─────────────────┘
```

## Directory Structure

```
.
├── main.js                 # Application entry point
├── package.json            # Dependencies & scripts
├── .env                    # Environment configuration
├── .gitignore             # Git ignore rules
├── controllers/            # Request handlers
│   └── productController.js
├── models/                # Mongoose schemas
│   └── product.js
├── services/              # Business logic & data abstraction
│   └── dataSource.js
├── routes/                # API & UI routing
│   ├── productRoutes.js
│   └── uiRoutes.js
├── validators/            # Input validation
│   └── productValidator.js
├── views/                 # EJS templates
│   ├── index.ejs
│   └── partials/
├── public/                # Static assets
│   ├── css/
│   ├── js/
│   ├── images/
│   └── uploads/          # User-uploaded files
├── docs/                  # Documentation
└── scripts/               # Automation & setup scripts
```

## Technology Stack

- **Runtime**: Node.js 16+
- **Framework**: Express.js 4.18+
- **Database**: MongoDB 4.x (with fallback to in-memory)
- **ORM**: Mongoose 7.x
- **Templating**: EJS 3.x
- **File Upload**: Multer 1.4+
- **Validation**: express-validator 6.14+
- **Environment**: dotenv 16.x
- **Development**: Nodemon 2.x

## Data Model

### Product Schema

```javascript
{
  _id: ObjectId,
  name: String (required),
  price: Number (required),
  color: String (required),
  category: String (optional),
  description: String,
  imageUrl: String,
  timestamps: {
    createdAt: Date,
    updatedAt: Date
  }
}
```

**Sample Product:**
```json
{
  "_id": "64a1b2c3d4e5f6g7h8i9j0k1",
  "name": "iPhone 14 Pro Max",
  "price": 1099,
  "color": "space-black",
  "category": "phone-tablet",
  "description": "6.7‑inch Super Retina XDR display, A16 Bionic chip",
  "imageUrl": "/uploads/iphone-pro-max.jpg",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

## API Endpoints

### Products API (REST)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/products` | List all products (supports search) | Public |
| GET | `/products/:id` | Get product by ID | Public |
| POST | `/products` | Create new product | Public |
| PUT | `/products/:id` | Replace entire product | Public |
| PATCH | `/products/:id` | Partial update of product | Public |
| DELETE | `/products/:id` | Delete product | Public |

**Query Parameters:**
- `search`: Filter products by name (case-insensitive)

**Request/Response Format:**
```json
{
  "data": { /* product object */ },
  "hostname": "server-hostname",
  "source": "mongodb|in-memory"
}
```

### UI Routes

| Route | Description |
|-------|-------------|
| `/` | Product management dashboard |

## Request/Response Examples

### List Products
```bash
curl http://localhost:3000/products?search=iPhone
```

**Response:**
```json
{
  "data": [
    {
      "_id": "...",
      "name": "iPhone 14 Pro Max",
      "price": 1099,
      "color": "space-black",
      "category": "phone-tablet",
      "description": "...",
      "imageUrl": "/uploads/...",
      "createdAt": "...",
      "updatedAt": "..."
    }
  ],
  "hostname": "my-server",
  "source": "mongodb"
}
```

### Create Product with Image
```bash
curl -X POST \
  -F "name=MacBook Air" \
  -F "price=1199" \
  -F "color=midnight" \
  -F "category=laptop" \
  -F "description=M2 Chip" \
  -F "imageFile=@/path/to/image.jpg" \
  http://localhost:3000/products
```

## Startup Behavior

1. **Initialization**: Application attempts to connect to MongoDB
   - Connection timeout: 3 seconds
   - If successful: Uses MongoDB as primary data store
   - If fails: Switches to in-memory storage

2. **Database Setup** (MongoDB only):
   - Ensures `products` collection exists
   - If empty, seeds 10 sample Apple products

3. **File System**:
   - Creates `public/uploads/` directory if missing
   - Serves uploaded images statically

4. **Server Start**:
   - Listens on port from `$PORT` env var (default: 3000)
   - Logs startup status and data source

## Data Persistence

### MongoDB
- **Permanent** storage
- **Persistent** across server restarts
- **Scalable** for production

### In-Memory Store
- **Temporary** storage (RAM only)
- **Lost** on server restart
- **Single-instance** only (not distributed)

## Image Handling

- **Storage**: Disk-based in `public/uploads/`
- **Serving**: Static file serving via Express
- **Cleanup**: Old images deleted when product updated/deleted
- **Path**: Relative URLs stored in database (`/uploads/<filename>`)

## Security Considerations

- **Validation**: Input validation via express-validator
- **File Uploads**: Handled via Multer (configurable limits)
- **Secrets**: Environment variables via .env (keep secret)
- **CORS**: Not explicitly configured (consider adding for API)
- **Rate Limiting**: Not implemented (recommend for production)

## Environment Variables

```bash
PORT=3000                                      # Server port
MONGO_URI=mongodb://localhost:27017/products_db  # MongoDB connection string
```

## Development vs Production

### Development Setup
- Use `npm run dev` (with Nodemon for auto-reload)
- In-memory database is acceptable
- Local file uploads

### Production Setup
- Use `npm start`
- Requires MongoDB connection
- Use cloud storage for uploads (S3/Cloudinary)
- Implement SSL/TLS
- Add authentication/authorization
- Enable rate limiting
- Set up monitoring and logging
