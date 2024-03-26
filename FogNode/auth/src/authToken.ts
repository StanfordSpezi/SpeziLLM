//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import { Request, Response } from 'express';

// Extract bearer token from the request
export function getTokenFromRequest(req: Request, res: Response): string | null {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
        console.log('SpeziLLMFog: Unauthorized - Authorization header is missing');
        res.status(401).send('SpeziLLMFog: Unauthorized - Authorization header is missing');
        return null;
    }

    if (!authHeader.startsWith('Bearer ')) {
        console.log('SpeziLLMFog: Unauthorized - Authorization header is not a Bearer token');
        res.status(401).send('SpeziLLMFog: Unauthorized - Authorization header is not a Bearer token');
        return null;
    }

    const token = authHeader.substring(7); // "Bearer " is 7 characters long
    if (!token) {
        console.log('SpeziLLMFog: Unauthorized - Token is missing in Authorization header');
        res.status(401).send('SpeziLLMFog: Unauthorized - Token is missing in Authorization header');
        return null;
    }

    return token;
}