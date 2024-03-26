#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

FROM node:21-alpine3.18

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
