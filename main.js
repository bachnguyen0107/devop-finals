require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const os = require('os');
const productRoutes = require('./routes/productRoutes');
const dataSource = require('./services/dataSource');
const uiRoutes = require('./routes/uiRoutes');
const path = require('path');
const fs = require('fs'); 

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// view engine and static
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', uiRoutes);
app.use('/products', productRoutes);

const PORT = process.env.PORT || 3000;

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function connectToMongoWithRetry(mongoUri, attempts = 15, delayMs = 2000) {
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      await mongoose.connect(mongoUri, {
        serverSelectionTimeoutMS: 2000
      });
      return true;
    } catch (err) {
      console.log(`MongoDB connection attempt ${attempt}/${attempts} failed: ${err.message}`);
      if (attempt < attempts) {
        await wait(delayMs);
      }
    }
  }

  return false;
}

async function start() {
  // Đảm bảo thư mục uploads tồn tại
  const uploadsDir = path.join(__dirname, 'public', 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log(`Created uploads directory at ${uploadsDir}`);
  }

  const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/products_db';
  const usingMongo = await connectToMongoWithRetry(mongoUri);
  if (usingMongo) {
    console.log('Connected to MongoDB — using mongodb as data source.');
  } else {
    console.log('Failed to connect to MongoDB within 3s — falling back to in-memory database.');
  }

  await dataSource.init(usingMongo);

  app.listen(PORT, () => {
    console.log(`Server listening on port http://localhost:${PORT} — hostname: ${os.hostname()}`);
    console.log(`Data source in use: ${dataSource.isMongo ? 'mongodb' : 'in-memory'}`);
  });
}

start();

module.exports = app;
