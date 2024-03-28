#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

FROM alpine:3.19

LABEL org.opencontainers.image.authors="Philipp Zagar <zagar@stanford.edu>" \
      org.opencontainers.image.version="0.1" \
      org.opencontainers.image.title="stanfordspezi/firebase-emulator-auth" \
      org.opencontainers.image.description="SpeziLLMFog Firebase Emulator Auth" \
      org.opencontainers.image.url="https://ghcr.io/stanfordspezi/firebase-emulator-auth" \
      org.opencontainers.image.source="https://github.com/StanfordSpezi/SpeziLLM"

# Install Firebase CLI
RUN npm install -g firebase-tools

WORKDIR /app

# Copy firebase emulator config files
COPY .firebaserc .firebaserc
COPY firebase.json firebase.json

# Expose web ui and auth service
EXPOSE 4000 9099

# Run the Firebase Emulators
CMD ["firebase", "emulators:start"]
