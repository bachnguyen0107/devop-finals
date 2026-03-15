// PM2 Ecosystem Configuration
// File location: ~/product-api/ecosystem.config.js (optional, for reference)
// Usage: pm2 start ecosystem.config.js

module.exports = {
  apps: [
    {
      name: 'product-api',
      script: './main.js',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
        MONGO_URI: 'mongodb://localhost:27017/products_db'
      },
      // Auto restart on crash
      autorestart: true,
      // Max memory before restart
      max_memory_restart: '1G',
      // Logs
      out_file: './logs/pm2-out.log',
      error_file: './logs/pm2-error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      // Watch for changes (dev mode)
      watch: false,
      ignore_watch: ['node_modules', 'logs', 'public/uploads']
    }
  ]
};
