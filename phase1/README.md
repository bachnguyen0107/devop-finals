# Product API + UI (Express + MongoDB, in‑memory fallback)

This is a project (Model – View – Controller) built with **Node.js + Express**. It stores product data in **MongoDB** via **Mongoose**.  
If the server cannot connect to MongoDB during startup (3s timeout), the application automatically falls back to an **in‑memory** data store and keeps running.
---

## Main Features

- Full **REST API** for managing products: CRUD (`GET / POST / PUT / PATCH / DELETE`).
- Server‑side rendered **UI** using `EJS` + `Bootstrap` for product management (main screen at `/`).
- Each JSON response includes extra metadata: `hostname` and `source` (whether data comes from `mongodb` or `in-memory`).
- **Image upload** for products:
  - Images are stored on disk under `public/uploads/`.
  - The `imageUrl` field on a product stores a **relative** path (`/uploads/<filename>`).
  - When a product is updated with a new image or deleted, the old image file in `/uploads/` is removed from disk.
- On first successful startup with MongoDB and an empty collection, the app **seeds 10 sample Apple products** into MongoDB.
- **Category support**:
  - Each product has a `category` field (e.g. `phone-tablet`, `laptop`, …).
  - Category can be selected in the UI and is displayed in the product table.
- **Search by name** on the UI:
  - A search box on `/` filters products by `name` (case‑insensitive).
  - Implemented in a way that works for both MongoDB and the in‑memory data source.

---

## Project Structure

- `main.js` – Entrypoint:
  - Tries to connect to MongoDB (3s timeout).
  - Falls back to in‑memory data store if connection fails.
  - Starts the Express server.
- `models/product.js` – Mongoose schema:

  ```text
  name        : String (required)
  price       : Number (required)
  color       : String (required)
  description : String (optional)
  imageUrl    : String (optional, relative path to uploaded image)
  category    : String (optional; e.g. "phone-tablet", "laptop", ...)
  ```

- `services/dataSource.js` – Abstraction layer between MongoDB and in‑memory storage:
  - Handles seeding sample products.
  - Exposes CRUD methods (`getAll`, `getById`, `create`, `replace`, `patch`, `remove`).
  - Deletes image files from disk when needed.
- `controllers/` – Controllers that implement request/response logic for API and UI.
- `routes/` – Route definitions:
  - `/products` – REST API endpoints.
  - `/` – UI routes rendering EJS views.
- `views/` – `EJS` templates for the web UI (list page, modal form, etc.).
- `public/` – Static assets:
  - CSS, client‑side JS, images.
  - `uploads/` – uploaded product images (served statically by Express).

---

## Requirements & Configuration

- **Node.js** 16+ (or a compatible version) and `npm`.
- Environment file `.env` (a sample is already included in the repo):

  ```text
  PORT=3000
  MONGO_URI=mongodb://localhost:27017/products_db
  ```

If your MongoDB instance requires username/password or runs on a different host/port, update `MONGO_URI` accordingly.

---

## Install & Run Locally

1. Install dependencies:

   ```bash
   cd path/to/sample-midterm-node.js-project
   npm install
   ```

2. Start the server:

   ```bash
   # Production-style (plain node)
   npm start

   # Or development mode with nodemon (auto reload)
   npm run dev
   ```

3. Open the browser at: `http://localhost:3000/`

   - The home page shows the product list.
   - You can **Add / Edit / Delete** products.
   - You can upload an image for each product.
   - You can pick a **category** and search products by **name** using the search box at the top.

---

## JSON API – Main Endpoints

All endpoints return JSON and include `hostname` and `source` metadata.

- `GET /products` – Get list of products.

  - Optional query parameter:
    - `search` – filter by product name (case‑insensitive).

- `GET /products/:id` – Get details of one product.

- `POST /products` – Create a new product.  
  Supports `multipart/form-data` to upload an image.

  - File field:
    - `imageFile` – image file to upload.
  - Text fields:
    - `name` (string, required)
    - `price` (number, required)
    - `color` (string, required)
    - `description` (string, optional)
    - `category` (string, optional; e.g. `phone-tablet`, `laptop`, …)

- `PUT /products/:id` – Replace a product completely.  
  Also supports `multipart/form-data` for image upload.

- `PATCH /products/:id` – Partially update a product.  
  Also supports `multipart/form-data`.

- `DELETE /products/:id` – Delete a product and its associated image file if it resides under `/uploads/`.

### Example: create product with image (curl)

```bash
curl -X POST http://localhost:3000/products \
  -F "name=My Device" \
  -F "price=199" \
  -F "color=black" \
  -F "description=Note" \
  -F "category=phone-tablet" \
  -F "imageFile=@/path/to/photo.jpg"
```

> Note: The UI on the home page uses `fetch` + `FormData` to send files, so you do not need to handle the request manually when using the built‑in UI.

---

## Important Runtime Behavior

- On startup, `main.js` attempts to connect to MongoDB with `serverSelectionTimeoutMS: 3000`.
  - If the connection fails, the app logs a message and uses the **in‑memory** data store for the entire process lifetime.
- When MongoDB connects successfully and the `products` collection is empty, the app automatically **seeds 10 sample Apple products** (with `name`, `price`, `color`, `description`, and empty `imageUrl`).
- Images are stored under `public/uploads/` and served as static files by Express.  
  Only the relative path (e.g. `/uploads/abc123.png`) is saved in the database.
- When updating a product with a new image or deleting a product, if the old image file exists under `/uploads/`, it is deleted from disk to avoid orphaned files.

---

## Limitations & Recommendations

- The server currently allows file uploads and stores images directly on the local disk.  
  This is fine for demos and development, but not ideal for production in terms of backup, scaling, and bandwidth.
  - For production, consider using a cloud storage service (e.g. S3, Cloudinary) and storing only the image URL in the database.
- For better security and robustness, you may want to:
  - Enforce maximum upload size.
  - Restrict accepted MIME types to `image/*`.
  - Add stronger validation rules for product fields.

---

## Useful Commands

- Install `nodemon` globally (optional):

  ```bash
  npm i -g nodemon
  ```

- Check logs in the terminal to see whether the app is currently using **MongoDB** or **in‑memory** as its data source.

---

## Possible Extensions

Some ideas for extending this sample:

- Add stricter file validation (size & MIME type).
- Move image storage to S3/Cloudinary (requires credentials).
- Add a product detail page.
- Implement pagination for the product list.
- Add more advanced search/filtering (by category, price range, etc.).