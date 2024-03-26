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
