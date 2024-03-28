//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import express, { Request, Response } from 'express';
import admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import { initializeFirebase } from './firebase';
import { getTokenFromRequest } from './authToken';

dotenv.config();

// Initialize Firebase Admin SDK
initializeFirebase();

// Create a new express.js application
const app = express();
const port: number = parseInt(process.env.PORT || '3000', 10);

// Serve authorization on all routes
app.all('*', async (req: Request, res: Response) => {
    const token = getTokenFromRequest(req, res);

    if (!token) {
        return;
    }

    try {
        // Verify the received bearer token via firebase admin SDK
        const decodedToken = await admin.auth().verifyIdToken(token);

        // Possibly add additional checks, e.g. verify if user is allowed to access the fog LLM via token claims
        // ...

        console.log('SpeziLLMFog: Authorized - Valid token');
        return res.status(200).send('SpeziLLMFog: Authorized - Valid token');
    } catch (error) {
        console.log('SpeziLLMFog: Unauthorized - Invalid user ID token ', error);
        return res.status(403).send(`SpeziLLMFog: Unauthorized - Invalid Firebase user ID token: ${error}`);
    }
});

// Start the server on port 3000 or the configured port
app.listen(port, () => {
    console.log(`SpeziLLMFog: Auth service listening at port ${port}`);
});