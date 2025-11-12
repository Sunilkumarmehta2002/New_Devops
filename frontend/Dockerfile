# Use Node LTS base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first (better caching)
COPY package*.json ./

# Install dependencies (include devDependencies so Vite is available inside the image)
RUN npm install

# Copy rest of the backend source code
COPY . .

# Expose frontend dev server port
EXPOSE 3000

# Start the Vite dev server and listen on all interfaces so the host can reach it
# the "--" separates npm args from the script args
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]
