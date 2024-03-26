# Stage 1: Build stage
FROM node:21-alpine3.18 AS builder

WORKDIR /usr/src/app

# Install npm dependencies
COPY package*.json ./
RUN npm install

# Copy source code and compile TypeScript project
COPY tsconfig.json ./
COPY src/ ./src
RUN npm run build

# Stage 2: Runtime stage
FROM node:21-alpine3.18

WORKDIR /usr/src/app

# Copy compiled files and necessary npm packages from the builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package.json ./package.json

# Start the nodeJS application
CMD [ "node", "dist/index.js" ]
