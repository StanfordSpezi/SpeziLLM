//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import admin from 'firebase-admin';

type EnvVar = string | undefined;

// Initialize Firebase Admin based on environment
export const initializeFirebase = (): void => {
    const useFirebaseEmulator: EnvVar = process.env.USE_FIREBASE_EMULATOR;
    const firebaseAuthEmulatorHost: EnvVar = process.env.FIREBASE_AUTH_EMULATOR_HOST;
    const firebaseProjectId: EnvVar = process.env.FIREBASE_PROJECT_ID;

    if (useFirebaseEmulator) {
        if (!firebaseAuthEmulatorHost || !firebaseProjectId) {
            throw new Error(`Environment variables FIREBASE_AUTH_EMULATOR_HOST and FIREBASE_PROJECT_ID are not properly set.`);
        }

        process.env["FIREBASE_AUTH_EMULATOR_HOST"] = firebaseAuthEmulatorHost;

        admin.initializeApp({
            projectId: firebaseProjectId,
        });
    } else {
        const serviceAccount = require("../serviceAccountKey.json");

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
    }
};