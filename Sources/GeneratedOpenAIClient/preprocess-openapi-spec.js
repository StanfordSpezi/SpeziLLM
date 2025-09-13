//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

const fs = require("fs");
const yaml = require("js-yaml");

// Load OpenAPI file path from config or use default
const openapiPath = process.env.npm_package_config_openapiFile ?? "openapi.yaml";

// Spezi copyright header to prepend to the output file
const header = `#
# This source file is part of the Stanford Spezi open source project.
# It is based on the official OpenAI OpenAPI spec with modifications by the Spezi project authors: https://github.com/openai/openai-openapi/blob/master/openapi.yaml
#
# SPDX-FileCopyrightText: 2024 Stanford University, OpenAI, and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
# 

`;

// Load OpenAPI YAML
let openapiDoc = yaml.load(fs.readFileSync(openapiPath, "utf8"));

/**
 * Recursively remove deprecated fields from the OpenAPI document.
 * This prevents build warnings due to deprecated API fields in generated Swift code.
 */
function removeDeprecated(obj) {
  if (Array.isArray(obj)) {
    return obj.map(removeDeprecated).filter(Boolean);
  } else if (obj && typeof obj === "object") {
    if (obj.deprecated) return undefined; // Remove deprecated objects

    const newObj = {};
    for (const [key, value] of Object.entries(obj)) {
      const cleanedValue = removeDeprecated(value);
      if (cleanedValue !== undefined) newObj[key] = cleanedValue;
    }
    return Object.keys(newObj).length ? newObj : undefined; // Remove empty objects
  }
  return obj;
}

/**
 * Remove a specific `oneOf` `required` block as Swift OpenAPI generator doesn't support it yet.
 * See: https://github.com/apple/swift-openapi-generator/issues/739
 */
function removeSpecificOneOf(obj) {
  if (Array.isArray(obj)) {
    return obj.map(removeSpecificOneOf).filter(Boolean);
  } else if (obj && typeof obj === "object") {
    Object.keys(obj).forEach((key) => {
      obj[key] = removeSpecificOneOf(obj[key]);
    });

    if ("oneOf" in obj && Array.isArray(obj.oneOf)) {
      const requiredBlocks = [
        { required: ["vector_store_ids"] },
        { required: ["vector_stores"] },
      ];
      if (JSON.stringify(obj.oneOf) === JSON.stringify(requiredBlocks)) {
        delete obj.oneOf;
      }
    }
  }
  return obj;
}

/**
 * Rename `sessions` to `num_sessions` in `UsageCodeInterpreterSessionsResult.required`.
 * See: https://github.com/openai/openai-openapi/issues/421
 */
function fixRequiredSessions(obj) {
  const requiredFields = obj?.components?.schemas?.UsageCodeInterpreterSessionsResult?.required;
  if (Array.isArray(requiredFields)) {
    obj.components.schemas.UsageCodeInterpreterSessionsResult.required = requiredFields.map((field) =>
      field === "sessions" ? "num_sessions" : field
    );
  }
  return obj;
}

/**
 * Remove `status` from `required` in `OpenAIFile` if the `status` property was removed due to deprecation.
 */
function fixRequiredStatus(obj) {
  const schema = obj?.components?.schemas?.OpenAIFile;
  if (schema?.required && Array.isArray(schema.required)) {
    if (!schema.properties?.status) {
      schema.required = schema.required.filter((field) => field !== "status");
    }
  }
  return obj;
}

/**
 * Recursively remove $ref references to deleted schemas.
 */
function removeInvalidRefs(obj) {
  if (Array.isArray(obj)) {
    return obj.map(removeInvalidRefs).filter(Boolean);
  } else if (obj && typeof obj === "object") {
    if (obj.$ref && removedSchemas.has(obj.$ref)) return undefined; // Remove invalid references

    const newObj = {};
    for (const [key, value] of Object.entries(obj)) {
      const cleanedValue = removeInvalidRefs(value);
      if (cleanedValue !== undefined) newObj[key] = cleanedValue;
    }
    return Object.keys(newObj).length ? newObj : undefined; // Remove empty objects
  }
  return obj;
}

/**
 * Ensures that the `name` property is present in the OpenAPI spec, as it is
 * missing in the official docs for `components.schemas.RealtimeServerEventResponseFunctionCallArgumentsDone`.
 *
 * See https://community.openai.com/t/realtime-api-docs-missing-name-property-for-the-response-function-call-arguments-done-server-event
 */
function fixMissingNameProperty(obj) {
    if (obj == null || typeof obj !== "object") return undefined

    const clone = structuredClone(obj)
    const schema = clone?.components?.schemas?.RealtimeServerEventResponseFunctionCallArgumentsDone

    if (schema?.properties && !("name" in schema.properties)) {
        schema.properties.name = {
            type: 'string',
            description: 'The name of the function to call.'
        }
    }

    if (Array.isArray(schema?.required) && !schema.required.includes("name")) {
      schema.required.push("name")
    }

    return clone
}


/**
 * Start applying transformations.
 */
if (openapiDoc.paths) openapiDoc.paths = removeDeprecated(openapiDoc.paths);

// Remove deprecated schemas and track removed schema names
const removedSchemas = new Set();
if (openapiDoc.components?.schemas) {
  for (const [key, value] of Object.entries(openapiDoc.components.schemas)) {
    if (value.deprecated) {
      removedSchemas.add(`#/components/schemas/${key}`);
      delete openapiDoc.components.schemas[key];
    }
  }
}

// Remove deprecated components
if (openapiDoc.components) {
  for (const section of ["parameters", "requestBodies", "responses", "schemas"]) {
    if (openapiDoc.components[section]) {
      openapiDoc.components[section] = removeDeprecated(openapiDoc.components[section]);
    }
  }
}

// Apply additional transformations
openapiDoc = removeSpecificOneOf(openapiDoc);
openapiDoc = removeInvalidRefs(openapiDoc);
openapiDoc = fixRequiredSessions(openapiDoc);
openapiDoc = fixRequiredStatus(openapiDoc);
openapiDoc = fixMissingNameProperty(openapiDoc);

// Convert OpenAPI spec back to YAML, preserving multi-line formatting
const cleanedYaml = yaml.dump(openapiDoc, {
  sortKeys: false, // Preserve key order
  lineWidth: 0, // Prevent automatic line wrapping
  noCompatMode: true, // Ensure modern YAML 1.2+ behavior
  quotingType: '"', // Use double quotes for strings
  forceQuotes: false, // Do not force unnecessary quotes
  indent: 2, // Use consistent 2-space indentation
  skipInvalid: true, // Prevent errors due to unknown types
  styles: { "!!str": "folded" }, // Preserve multi-line string formatting
});

// Prepend the copyright header to the YAML content
const finalOutput = header + cleanedYaml;

// Write the final OpenAPI spec to file
fs.writeFileSync(openapiPath, finalOutput, "utf8");

console.log("✅ Successfully preprocessed OpenAPI spec and prepended Spezi copyright header.");
