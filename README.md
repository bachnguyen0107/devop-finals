# DevOps Final Project: Production-Grade CI/CD System
## Product Management API + Web UI

A **production-grade CI/CD system** demonstrating complete DevOps practices:
- Full REST API for product management (CRUD operations)
- Server-rendered web UI with Bootstrap
- End-to-end automated CI/CD pipeline (GitHub Actions)
- Monitoring & observability stack (Prometheus + Grafana)
- HTTPS/SSL support with Nginx reverse proxy
- Horizontal scaling with 3 web service replicas

**Architecture:** Tier 2/3 containerized deployment on AWS EC2 (t2.micro optimized)

---

## Project Features

- **Full REST API** for product management: CRUD operations (`GET / POST / PUT / PATCH / DELETE`)
- **Server-rendered UI** with Bootstrap for intuitive product management at `/`
- **Image upload support**: Images stored on disk with automatic cleanup on product deletion
- **MongoDB persistence** with in-memory fallback if database is unavailable
- **Category support**: Filter and manage products by category
- **Search functionality**: Find products by name (case-insensitive)
- **Metadata tracking**: Each response includes hostname and data source information

---

## Project Structure
docker-compose -f docker-compose.yml up -d --build
```
devop-finals/
├── .github/workflows/
│   └── ci-cd.yml                    # GitHub Actions CI/CD pipeline (lint → security → build → deploy)
docker-compose -f docker-compose.yml up -d --build
│   └── main.tf                      # IaC: AWS EC2, security groups, auto-provisioning
├── prometheus/
│   ├── prometheus.yml               # Prometheus configuration (metrics collection)
│   └── grafana-datasources.yml      # Grafana datasources (Prometheus integration)
├── package.json                     # Dependencies & npm scripts
├── README.md                        # This file
├── TESTING_CHECKLIST.md             # Comprehensive testing guide before demo
├── controllers/                     # Express request handlers
├── models/                          # MongoDB/Mongoose schemas
├── validators/                      # Input validation logic
├── views/                           # EJS templatesför web UI
├── public/                          # Static assets (CSS, JS, images)
└── evidence/                        # Screenshots & deployment logs
```

---

## Application Features

```
- name        : String (required)
- price       : Number (required)
- color       : String (required)
- description : String (optional)
- imageUrl    : String (optional, relative path)
The `services/dataSource.js` layer handles:
- MongoDB and in-memory storage abstraction

---
### Prerequisites
- **Docker** and **Docker Compose** installed
- **Git** for cloning the repository
### 1. Clone & Setup

```bash
git clone <repository-url>
```

Edit `.env` with your settings:
```env
MONGO_URI=mongodb://mongo:27017/products_db
```

**Production Deployment (EC2 - full stack):**
```

docker-compose -f docker-compose.yml up -d --build

### 4. Access the Application



## Local Development (Without Docker)

### Setup
```bash
npm install
npm run dev  # Runs with nodemon for auto-reload
# or
npm start    # Production mode with plain node
```

---

## Docker Compose Stack

**Web Service**
- Pulls pre-built image from Docker Hub
**MongoDB Service**
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
- **GET `/edit/:id`**: Edit product modal
- **POST `/update/:id`**: Update product via form
- **POST `/delete/:id`**: Delete product

---

## Image Upload


---

## Deployment Notes

### Production with Docker Compose
1. Build the web image locally or pull from Docker Hub
2. Deploy using `docker compose up -d`
3. Configure Nginx as reverse proxy (optional, for HTTPS/SSL)
### Environment Variables
- `MONGO_URI`: MongoDB connection string (default: mongodb://mongo:27017/products_db)

### Monitoring
- Check container status: `docker compose ps`
- View logs: `docker compose logs -f web`
- Stop stack: `docker compose down`

## CI/CD Pipeline (GitHub Actions)

1. **Code Quality & Linting** (`build-and-test`)

2. **Security Scanning** (`security-scan`) 
   - Trivy filesystem scan for vulnerabilities
   - Checks CRITICAL & HIGH severity issues
   - ✅ Pass: Proceed to image build

3. **Docker Build & Push** (`docker-build-push`)
   - Build Docker image from Dockerfile
   - Tag: `DOCKER_USERNAME/devop-final-web:latest` and `:SHA`
   - ✅ Success: Ready for deployment
4. **Continuous Delivery** (`deploy`)
   - SSH into EC2 instance
   - Git pull latest code
   - Aggressive docker cleanup (free disk space)
   - Deploy using `docker-compose.yml` (single full-stack config)
   - Services auto-restart on failure

### GitHub Secrets Required
```
DOCKER_USERNAME       # Docker Hub username
DOCKER_PASSWORD       # Docker Hub access token
EC2_HOST             # EC2 public IP or domain
EC2_USERNAME         # EC2 user (ec2-user or ubuntu)
EC2_SSH_KEY          # EC2 private SSH key (PEM format)
```

### Workflow Configuration
## Infrastructure as Code (Terraform)

### AWS EC2 Provisioning

File: `terraform/main.tf`

**Features:**
- Automated EC2 instance creation (Ubuntu 22.04 LTS, t2.micro)
- Security group with ingress rules (HTTP 80, HTTPS 443, SSH 22)
- Auto-install Docker and Docker Compose on launch

**Deployment:**
```bash
terraform init
terraform plan -var="key_name=your-aws-keypair" -var="aws_region=ap-southeast-1"
terraform apply
```

**Outputs:**
- EC2 instance public IP
- Security group ID
- Instance details for SSH access

---

## Monitoring & Observability

### Stack Components

**Prometheus** (port 9090)
- Metrics collection from cAdvisor
- Stores time-series data with 15-day retention
- Configuration: `prometheus/prometheus.yml`

**Grafana** (port 3001)
- Admin: admin/admin
- Pre-configured Prometheus datasource
- Container metrics dashboards
- Accessible: http://13.212.58.182:3001

**cAdvisor** (port 8080)
- Container metrics exporter
- Real-time CPU, memory, disk I/O monitoring
- Accessible: http://localhost:8080

### Demo Strategy
```bash
# 1. Production app running on EC2 (via docker-compose.yml)
# 2. Open Grafana and show live metrics
# 3. Simulate failure: docker kill <container>
# 4. Show container recovery in Grafana
```


---

## HTTPS & SSL Configuration

### Certificate Generation

Script: `generate-cert-ec2.sh`

Generates self-signed certificates for local/development:
```bash
./generate-cert-ec2.sh
# Creates: ./ssl/cert.pem, ./ssl/key.pem
```

For production, use AWS ACM or Let's Encrypt certificates.

### Nginx Configuration

- **HTTP (port 80)**: Redirects to HTTPS
- **HTTPS (port 443)**: Serves with cert.pem and key.pem
- **Reverse Proxy**: Forwards to web service (port 3000)
- **Load Balancing**: Distributes across 3 web replicas

Main config: `nginx.conf`

### Verification
```bash
curl -I https://devop-midterm2026.online/
# Expected: HTTP/1.1 200 OK
```

---

## Deployment Models & Strategies

### Production Deployment on EC2 (Lean Config - Tier 2)
**Services:** nginx, web (3 replicas), mongo  
**Deployment:** Automated via GitHub Actions on push to main  
**Auto-Recovery:** Container restart on failure  
**Data Persistence:** MongoDB volumes + application uploads

**Use Case:** Local testing, live demonstrations, full observability  
**Features:** Complete monitoring, failure simulation, metrics visualization
**Demo Use:** Show metrics without impacting production deployment
### Recommended Demo Setup
```bash
# Terminal 1: Production running on EC2
ssh ec2-user@your-ec2-ip "docker ps"

# Terminal 2: Monitoring stack locally (for demo)
docker-compose -f docker-compose.yml up -d --build
# Then open Grafana: http://13.212.58.182:3001
# Terminal 3: GitHub Actions tab
# Watch live deployment via SSH
```

---

## Testing & Validation

### Before Demonstrating to Instructor

**See: [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md) for comprehensive testing guide**

Quick verification:
```bash
# 1. SSH to EC2 and verify services
docker ps | grep -E "nginx|web|mongo"
# Expected: 8 containers running

# 2. Test application
curl http://13.212.58.182/products | jq '.data | length'
# Expected: JSON array with products

# 3. Check CI/CD success
# GitHub Actions → Latest run should be ✅ all green

# 4. Test monitoring (if running)
curl http://localhost:9090/api/v1/query?query=up
# Expected: JSON with prometheus targets
```

---

## Troubleshooting

**MongoDB connection fails**: App automatically falls back to in-memory storage. Check MONGO_URI in `.env`.

**Port 3000 already in use**: Update port mapping in `docker-compose.yml` or kill the process using port 3000.

**Images not persisting**: Ensure `uploads_data` volume is properly mounted in docker-compose.yml.

**Containers not starting**: Run `docker compose logs` to see detailed error messages.

**EC2 deployment fails "no space left on device"**: 
- Run `docker system prune -af --volumes`
- Use `docker-compose.yml` (full stack) and ensure disk has enough free space
- Check available disk: `df -h`

---

## Technologies

**Application Stack:**
- **Runtime**: Node.js 18 (Alpine Linux)
- **Framework**: Express.js 4.18
- **Database**: MongoDB 6.0 (via Docker)
- **Template Engine**: EJS 3.1
- **ORM**: Mongoose 7.0
- **Form Handling**: multer (file uploads), express-validator

**DevOps & Infrastructure:**
- **Containerization**: Docker & Docker Compose
- **Web Server**: Nginx (reverse proxy, load balancer, SSL/TLS)
- **CI/CD**: GitHub Actions (automated lint, security, build, deploy)
- **Infrastructure as Code**: Terraform (AWS EC2 provisioning)
- **Monitoring**: Prometheus (metrics), Grafana (dashboards), cAdvisor (container metrics)
- **Cloud Platform**: AWS EC2 (t2.micro, Ubuntu 22.04 LTS)
- **Source Control**: Git & GitHub

---

## Team & Submission

**Course**: DevOps Final Exam - Production-Grade CI/CD System  
**Submission Format**: GitHub repository + live demo + technical report

For testing and validation steps, refer to [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)

---

## License

ISC
