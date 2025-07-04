# ------------------------------
# Stage 1: Development / Build Stage
# ------------------------------

# Use an official Node.js 18 Alpine image to build the app
FROM node:18-alpine AS builder

# Set the working directory inside the container to /app
WORKDIR /app

# Install build tools needed to compile native modules
# - python3: for scripts that need Python
# - make and g++: to compile code during npm install
RUN apk add --no-cache python3 make g++

# Copy only the package.json and package-lock.json files
# This helps use Docker cache and avoid reinstalling dependencies unless they change
COPY package*.json ./

# Install exact versions of all dependencies for consistency and speed ( CI Means CLean Install)
RUN npm ci

# Copy all remaining source code and project files into the container
COPY . .

# Build the Next.js application (creates a production-ready version)
RUN npm run build

# ------------------------------
# Stage 2: Production / Run Stage
# ------------------------------

# Use a clean Node.js 18 Alpine image for running the built app
FROM node:18-alpine AS runner

# Set the working directory again for the production image
WORKDIR /app

# Copy only the necessary build output files from the builder stage

# 1. Copy the standalone server created by Next.js
COPY --from=builder /app/.next/standalone ./

# 2. Copy the static assets (JS, CSS, etc.)
COPY --from=builder /app/.next/static ./.next/static

# 3. Copy public folder (images, icons, etc.)
COPY --from=builder /app/public ./public

# Set environment variables
# Let Node.js know we are in production mode
# App will run on port 3000
ENV NODE_ENV=production   
ENV PORT=3000             

# Tell Docker that the container listens on port 3000
EXPOSE 3000

# Start the app using the Node.js standalone server created by Next.js
CMD ["node", "server.js"]
