#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

# Stage 1: Build stage
FROM node:21-alpine3.19 AS builder

LABEL org.opencontainers.image.authors="Philipp Zagar <zagar@stanford.edu>" \
      org.opencontainers.image.version="0.1" \
      org.opencontainers.image.title="stanfordspezi/firebase-auth-service" \
      org.opencontainers.image.description="SpeziLLMFog Firebase Authentication Service" \
      org.opencontainers.image.url="https://ghcr.io/stanfordspezi/firebase-auth-service" \
      org.opencontainers.image.source="https://github.com/StanfordSpezi/SpeziLLM"

WORKDIR /usr/src/app

# Install npm dependencies
COPY package*.json ./
RUN npm install

# Copy source code and compile TypeScript project
COPY tsconfig.json ./
COPY src/ ./src
RUN npm run build

# Stage 2: Runtime stage
FROM node:21-alpine3.19

WORKDIR /usr/src/app

# Copy compiled files and necessary npm packages from the builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package.json ./package.json

# Start the nodeJS application
CMD [ "node", "dist/index.js" ]
