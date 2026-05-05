FROM node:20-alpine

WORKDIR /app

# Copy only package manifests first for better caching
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev

# Copy application source
COPY . .

# Create runtime dirs (volumes will also mount here)
RUN mkdir -p public/uploads logs

EXPOSE 3000

CMD ["node", "main.js"]
