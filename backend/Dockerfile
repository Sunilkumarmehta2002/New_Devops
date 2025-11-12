# Use Node LTS base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy rest of the backend source code
COPY . .

# Expose backend port (application listens on 4000 by default)
EXPOSE 4000

# Start the server
CMD ["node", "index.js"]
