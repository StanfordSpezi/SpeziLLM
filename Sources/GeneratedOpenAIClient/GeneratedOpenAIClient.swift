//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//


// It appears that SPM requires the presence of at least one source file within the `GeneratedOpenAIClient`
// target to ensure it is recognized as a valid module. Without this file, SPM may not properly expose
// the target, preventing its import in dependent targets.

// This file serves as a placeholder to satisfy SPM’s module resolution requirements, ensuring that
// `GeneratedOpenAIClient` can be correctly referenced and imported in other targets within the package.
