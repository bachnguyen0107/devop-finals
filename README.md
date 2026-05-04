# Product API + UI (Express + MongoDB, Docker Deployment)

A full-stack Node.js + Express application with server-side rendered EJS UI for product management. Deployed using **Docker Compose** with MongoDB and Nginx reverse proxy.

---

## Features

- **Full REST API** for product management: CRUD operations (`GET / POST / PUT / PATCH / DELETE`)
- **Server-rendered UI** with Bootstrap for intuitive product management at `/`
- **Image upload support**: Images stored on disk with automatic cleanup on product deletion
- **MongoDB persistence** with in-memory fallback if database is unavailable
- **Category support**: Filter and manage products by category
- **Search functionality**: Find products by name (case-insensitive)
- **Metadata tracking**: Each response includes hostname and data source information

---

## Project Structure

```
.
├── main.js                    # Application entrypoint
├── package.json               # Dependencies
├── Dockerfile                 # Production container image
├── docker-compose.yml         # Full stack orchestration
├── .env.example              # Environment template
├── controllers/              # Request/response logic
├── models/                   # Mongoose schema definitions
├── routes/                   # API & UI route definitions
├── services/                 # Data source abstraction layer
├── validators/               # Input validation
├── views/                    # EJS templates
├── public/                   # Static assets (CSS, JS, images)
└── evidence/                 # Deployment screenshots & logs
```

---

## Application Features

### Product Schema
```
- name        : String (required)
- price       : Number (required)
- color       : String (required)
- description : String (optional)
- imageUrl    : String (optional, relative path)
- category    : String (optional)
```

### Data Source Abstraction
The `services/dataSource.js` layer handles:
- MongoDB and in-memory storage abstraction
- Automatic sample data seeding on first MongoDB connection
- Image file management (upload and cleanup)
- CRUD operations consistent across data sources

---

## Quick Start

### Prerequisites
- **Docker** and **Docker Compose** installed
- **Git** for cloning the repository

### 1. Clone & Setup

```bash
git clone <repository-url>
cd <project-directory>
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` with your settings:
```env
PORT=3000
MONGO_URI=mongodb://mongo:27017/products_db
```

For production with Docker Hub image, update the image name in `docker-compose.yml`:
```yaml
image: YOUR_DOCKERHUB_USERNAME/devop-midterm-web:1.0.0
```

### 3. Build & Deploy

```bash
# Build and start containers
docker compose up --build

# Or pull pre-built image and run
docker compose up
```

### 4. Access the Application

- **Web UI**: http://localhost:3000
- **API**: http://localhost:3000/products (JSON responses)

---

## Local Development (Without Docker)

### Prerequisites
- Node.js 16+ and npm
- MongoDB running locally (or update `MONGO_URI` in `.env`)

### Setup

```bash
npm install
npm run dev  # Runs with nodemon for auto-reload
# or
npm start    # Production mode with plain node
```

---

## Docker Compose Stack

The stack includes:

**Web Service**
- Pulls pre-built image from Docker Hub
- Exposes port 3000
- Persists uploaded files
- Depends on MongoDB service

**MongoDB Service**
- Official `mongo:6.0` image
- Persisted volume for data
- Internal Docker network communication

**Volumes**
- `mongo_data`: MongoDB database files
- `uploads_data`: User-uploaded product images
- `logs_data`: Application logs

**Restart Policy**: Both services have `restart: unless-stopped` for automatic recovery.

---

## API Endpoints

### GET `/products`
- **Params**: `category` (optional), `search` (optional)
- **Returns**: JSON array with products and metadata

### POST `/products`
- **Body**: `{ name, price, color, category, description, image }`
- **Returns**: Created product with ID

### GET `/products/:id`
- **Returns**: Single product

### PUT `/products/:id`
- **Body**: Complete product data (replaces entire document)
- **Returns**: Updated product

### PATCH `/products/:id`
- **Body**: Partial product data (updates only provided fields)
- **Returns**: Updated product

### DELETE `/products/:id`
- **Returns**: Deleted product ID
- **Side effect**: Removes associated image file from disk

---

## UI Routes

- **GET `/`**: Home page with product list, search, and category filter
- **POST `/upload`**: Handle image upload (multipart form)
- **GET `/edit/:id`**: Edit product modal
- **POST `/update/:id`**: Update product via form
- **POST `/delete/:id`**: Delete product

---

## Image Upload

- Images are stored in `public/uploads/`
- UI provides drag-and-drop or file selection
- `imageUrl` field stores relative path (e.g., `/uploads/abc123.jpg`)
- Automatically cleaned up when product is updated or deleted

---

## Deployment Notes

### Production with Docker Compose
1. Build the web image locally or pull from Docker Hub
2. Deploy using `docker compose up -d`
3. Configure Nginx as reverse proxy (optional, for HTTPS/SSL)
4. Ensure `.env` is properly configured on the server (not committed to git)
5. Use volumes for persistence

### Environment Variables
- `PORT`: Server port (default: 3000)
- `MONGO_URI`: MongoDB connection string (default: mongodb://mongo:27017/products_db)

### Monitoring
- Check container status: `docker compose ps`
- View logs: `docker compose logs -f web`
- Stop stack: `docker compose down`
- Full cleanup (remove volumes): `docker compose down -v`

---

## Deployment Strategy

### Production Deployment (EC2 - Optimized for t2.micro)
Uses **lean config** to fit disk constraints:
```bash
docker-compose -f docker-compose.prod.yml up -d --build
```
Services: nginx, web (3 replicas), mongo
- Fits in 2.1GB available disk space
- Essential services only for core functionality
- Deployed via GitHub Actions on git push to main

### Full Stack Deployment (Development/Demo)
Uses **full config** with monitoring stack:
```bash
docker-compose up -d --build
```
Services: nginx, web (3 replicas), mongo, prometheus, grafana, cadvisor
- Requires ~4GB disk space
- Complete monitoring and observability
- Used for local testing and live demonstrations

### Monitoring Stack (Optional - Can be added separately)
```bash
docker-compose -f docker-compose.monitoring.yml up -d
```
Services: prometheus, grafana, cadvisor
- Connects to existing app-network
- Grafana admin: admin/admin (port 3001)
- Prometheus: port 9090
- cAdvisor: port 8080

**Demo Strategy:**
1. Show production deployment on EC2 (via SSH or browser)
2. For monitoring demonstration: Start monitoring stack locally or on secondary host
3. Show end-to-end CI/CD: code change → GitHub Actions → production update
4. Demonstrate failure recovery and monitoring insights

---

## Troubleshooting

**MongoDB connection fails**: App automatically falls back to in-memory storage. Check MONGO_URI in `.env`.

**Port 3000 already in use**: Update port mapping in `docker-compose.yml` or kill the process using port 3000.

**Images not persisting**: Ensure `uploads_data` volume is properly mounted in docker-compose.yml.

**Containers not starting**: Run `docker compose logs` to see detailed error messages.

---

## Technologies

- **Runtime**: Node.js 18 (Alpine Linux)
- **Framework**: Express.js 4.18
- **Database**: MongoDB 6.0 (via Docker)
- **Template Engine**: EJS 3.1
- **ORM**: Mongoose 7.0
- **Form Handling**: multer (file uploads), express-validator
- **Containerization**: Docker & Docker Compose

---

## License

ISC
