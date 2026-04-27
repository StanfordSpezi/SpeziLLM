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
 * Convert OpenAPI 3.0-style boolean `exclusiveMinimum`/`exclusiveMaximum` to OpenAPI 3.1 numeric format.
 * In 3.0, `{ minimum: 0, exclusiveMinimum: true }` means "> 0".
 * In 3.1, the equivalent is `{ exclusiveMinimum: 0 }`.
 */
function fixExclusiveMinMax(obj) {
  if (Array.isArray(obj)) {
    return obj.map(fixExclusiveMinMax);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = fixExclusiveMinMax(obj[key]);
    }
    if (obj.exclusiveMinimum === true && obj.minimum !== undefined) {
      obj.exclusiveMinimum = obj.minimum;
      delete obj.minimum;
    }
    if (obj.exclusiveMaximum === true && obj.maximum !== undefined) {
      obj.exclusiveMaximum = obj.maximum;
      delete obj.maximum;
    }
  }
  return obj;
}

/**
 * Convert OpenAPI 3.0-style `nullable: true` to OpenAPI 3.1 syntax.
 * In 3.0: `{ type: "string", nullable: true }` means the value can be a string or null.
 * In 3.1: `{ type: ["string", "null"] }` is the equivalent.
 * If no `type` is specified, just remove the `nullable` property (the field's optionality
 * is handled by whether it appears in the `required` array).
 */
function convertNullable(obj) {
  if (Array.isArray(obj)) {
    return obj.map(convertNullable);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = convertNullable(obj[key]);
    }
    if (obj.nullable === true) {
      delete obj.nullable;
      if (typeof obj.type === "string") {
        obj.type = [obj.type, "null"];
      }
    } else if (obj.nullable === false) {
      delete obj.nullable;
    }
  }
  return obj;
}

/**
 * Simplify `anyOf: [X, {type: "null"}]` patterns to just X.
 * OpenAPI 3.1 uses this pattern for nullable types, but the swift-openapi-generator
 * doesn't always handle it correctly (e.g., it may skip generating named types like Metadata,
 * or fail to generate Value2Payload for nested anyOf-null patterns).
 * Swift handles nullability via optionals at the usage site, so the null variant is unnecessary.
 */
function simplifyAnyOfNull(obj) {
  if (Array.isArray(obj)) {
    return obj.map(simplifyAnyOfNull);
  } else if (obj && typeof obj === "object") {
    // Recurse first, then simplify
    for (const key of Object.keys(obj)) {
      obj[key] = simplifyAnyOfNull(obj[key]);
    }
    if (Array.isArray(obj.anyOf)) {
      const nonNull = obj.anyOf.filter(
        (item) => !(item && typeof item === "object" && item.type === "null" && Object.keys(item).length === 1)
      );
      if (nonNull.length < obj.anyOf.length) {
        // We removed a null type
        if (nonNull.length === 1) {
          // Merge the single remaining schema into this object, preserving any sibling keys (description, etc.)
          const remaining = nonNull[0];
          delete obj.anyOf;
          Object.assign(obj, remaining);
        } else if (nonNull.length > 1) {
          obj.anyOf = nonNull;
        }
      }
    }
  }
  return obj;
}

/**
 * Remove `application/json` content type from request bodies that also have `multipart/form-data`
 * and share the same schema $ref. The swift-openapi-generator generates multipart types that
 * don't conform to Encodable, causing compilation errors when the client also tries to use them for JSON.
 */
function fixDualContentType(obj) {
  if (!obj?.paths) return obj;

  for (const [pathKey, pathItem] of Object.entries(obj.paths)) {
    for (const method of ["get", "post", "put", "patch", "delete"]) {
      const operation = pathItem?.[method];
      const content = operation?.requestBody?.content;
      if (!content) continue;

      if (content["application/json"] && content["multipart/form-data"]) {
        const jsonRef = content["application/json"]?.schema?.$ref;
        const multipartRef = content["multipart/form-data"]?.schema?.$ref;
        if (jsonRef && multipartRef && jsonRef === multipartRef) {
          delete content["application/json"];
        }
      }
    }
  }
  return obj;
}

/**
 * Mark multipart request bodies as required where they are currently optional.
 * The swift-openapi-generator skips optional multipart request bodies.
 */
function fixOptionalMultipartBodies(obj) {
  if (!obj?.paths) return obj;

  for (const pathItem of Object.values(obj.paths)) {
    for (const method of ["get", "post", "put", "patch", "delete"]) {
      const operation = pathItem?.[method];
      if (!operation?.requestBody) continue;
      const content = operation.requestBody.content;
      if (content && content["multipart/form-data"] && !operation.requestBody.required) {
        operation.requestBody.required = true;
      }
    }
  }
  return obj;
}

/**
 * Remove properties that ended up as pure `{type: "null"}` after deprecated removal + simplifyAnyOfNull.
 * These happen when an `anyOf: [{deprecated: true, ...}, {type: "null"}]` has its deprecated branch removed,
 * leaving only the unsupported null type. Also removes them from the `required` array if present.
 */
function removeNullOnlyProperties(obj) {
  if (!obj?.components?.schemas) return obj;

  for (const schema of Object.values(obj.components.schemas)) {
    if (!schema.properties) continue;
    for (const [propName, propValue] of Object.entries(schema.properties)) {
      if (!propValue || typeof propValue !== "object") continue;

      const isNullOnly =
        // Direct {type: "null"}
        (propValue.type === "null") ||
        // {anyOf: [{type: "null"}]} — all alternatives are null
        (Array.isArray(propValue.anyOf) && propValue.anyOf.length > 0 &&
          propValue.anyOf.every((item) => item && typeof item === "object" && item.type === "null"));

      if (isNullOnly) {
        delete schema.properties[propName];
        if (Array.isArray(schema.required)) {
          schema.required = schema.required.filter((r) => r !== propName);
        }
      }
    }
  }
  return obj;
}

/**
 * Remove entries from `required` arrays that don't have a corresponding entry in `properties`.
 * These are OpenAI spec bugs where a field is listed as required but never defined.
 */
function removeOrphanedRequired(obj) {
  if (Array.isArray(obj)) {
    return obj.map(removeOrphanedRequired);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = removeOrphanedRequired(obj[key]);
    }
    if (Array.isArray(obj.required) && obj.properties && typeof obj.properties === "object") {
      const propNames = new Set(Object.keys(obj.properties));
      obj.required = obj.required.filter((r) => propNames.has(r));
      if (obj.required.length === 0) delete obj.required;
    }
  }
  return obj;
}

/**
 * Replace `$recursiveRef` with a standard `$ref` pointing to the schema itself.
 * `$recursiveRef: '#'` is not supported by swift-openapi-generator.
 * For CompoundFilter, we replace it with `$ref: '#/components/schemas/CompoundFilter'`.
 */
function fixRecursiveRef(obj) {
  if (!obj?.components?.schemas) return obj;

  for (const [schemaName, schema] of Object.entries(obj.components.schemas)) {
    // Remove $recursiveAnchor (not needed with $ref)
    if (schema.$recursiveAnchor !== undefined) {
      delete schema.$recursiveAnchor;
    }
    replaceRecursiveRefs(schema, `#/components/schemas/${schemaName}`);
  }
  return obj;
}

function replaceRecursiveRefs(obj, selfRef) {
  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      if (obj[i] && typeof obj[i] === "object") {
        if (obj[i].$recursiveRef === "#") {
          obj[i] = { $ref: selfRef };
        } else {
          replaceRecursiveRefs(obj[i], selfRef);
        }
      }
    }
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      if (obj[key] && typeof obj[key] === "object") {
        if (obj[key].$recursiveRef === "#") {
          obj[key] = { $ref: selfRef };
        } else {
          replaceRecursiveRefs(obj[key], selfRef);
        }
      }
    }
  }
}

/**
 * Fix `minItems` placed on string `items` instead of on the parent array.
 * E.g., VectorStoreSearchRequest.query.oneOf[1].items has `minItems: 1` on a string type.
 * Move it up to the parent array schema.
 */
function fixMisplacedMinItems(obj) {
  if (Array.isArray(obj)) {
    return obj.map(fixMisplacedMinItems);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = fixMisplacedMinItems(obj[key]);
    }
    // If this is an array type with items that have minItems, move it up
    if (obj.type === "array" && obj.items && typeof obj.items === "object" && obj.items.minItems !== undefined) {
      if (obj.minItems === undefined) {
        obj.minItems = obj.items.minItems;
      }
      delete obj.items.minItems;
    }
  }
  return obj;
}

/**
 * Remove `anyOf`/`not` patterns that only contain `required`-only sub-schemas (no properties).
 * These are "exactly one of" constraints (e.g., ImageRefParam, CreateVectorStoreFileBatchRequest)
 * that swift-openapi-generator interprets as separate sub-schemas with missing properties.
 * Swift can't express these constraints, so we remove them.
 */
function removeRequiredOnlyAnyOf(obj) {
  if (Array.isArray(obj)) {
    return obj.map(removeRequiredOnlyAnyOf);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = removeRequiredOnlyAnyOf(obj[key]);
    }
    if (Array.isArray(obj.anyOf)) {
      const allRequiredOnly = obj.anyOf.every(
        (item) => item && typeof item === "object" && item.required && Object.keys(item).length === 1
      );
      if (allRequiredOnly) {
        delete obj.anyOf;
        // Also remove the complementary `not` constraint if present
        if (obj.not && obj.not.required) {
          delete obj.not;
        }
      }
    }
  }
  return obj;
}

/**
 * Fix allOf schemas where required fields reference properties from other allOf members.
 * For each allOf member that has `required` fields not in its own `properties`,
 * remove those orphaned required entries. The generator treats each allOf member separately.
 */
function fixAllOfOrphanedRequired(obj) {
  if (Array.isArray(obj)) {
    return obj.map(fixAllOfOrphanedRequired);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = fixAllOfOrphanedRequired(obj[key]);
    }
    if (Array.isArray(obj.allOf)) {
      for (const member of obj.allOf) {
        if (member && typeof member === "object" && Array.isArray(member.required) && member.properties) {
          const propNames = new Set(Object.keys(member.properties));
          member.required = member.required.filter((r) => propNames.has(r));
          if (member.required.length === 0) delete member.required;
        }
      }
    }
  }
  return obj;
}

/**
 * Fix CreateMessageRequest.attachments where `required` from the array item's inline object
 * sits at the array level after simplifyAnyOfNull merges the anyOf.
 * More generally: if an array-type schema has a `required` array (which is an object-schema keyword),
 * move it into the `items` schema if items is an object type.
 */
function fixArrayWithRequired(obj) {
  if (Array.isArray(obj)) {
    return obj.map(fixArrayWithRequired);
  } else if (obj && typeof obj === "object") {
    for (const key of Object.keys(obj)) {
      obj[key] = fixArrayWithRequired(obj[key]);
    }
    if (obj.type === "array" && Array.isArray(obj.required) && obj.items && typeof obj.items === "object") {
      if (!obj.items.required) {
        obj.items.required = obj.required;
      }
      delete obj.required;
    }
  }
  return obj;
}

/**
 * Resolve a `$ref` like `#/components/schemas/Foo` to the actual schema object.
 */
function resolveRef(rootDoc, ref) {
  if (typeof ref !== "string" || !ref.startsWith("#/")) return undefined;
  const segments = ref.slice(2).split("/");
  let cur = rootDoc;
  for (const seg of segments) {
    if (cur == null || typeof cur !== "object") return undefined;
    cur = cur[seg];
  }
  return cur;
}

/**
 * Search a schema (and its `allOf` members) for a property by name and return its `enum` values.
 * Follows `$ref`s as needed. Returns an array of strings, or [] if not found.
 */
function findDiscriminatorEnumValues(rootDoc, schema, propName, visited = new Set()) {
  if (!schema || typeof schema !== "object") return [];

  if (schema.$ref) {
    if (visited.has(schema.$ref)) return [];
    visited.add(schema.$ref);
    const resolved = resolveRef(rootDoc, schema.$ref);
    return findDiscriminatorEnumValues(rootDoc, resolved, propName, visited);
  }

  // Direct property
  const prop = schema.properties?.[propName];
  if (prop) {
    if (Array.isArray(prop.enum) && prop.enum.length > 0) {
      return prop.enum.map(String);
    }
    if (typeof prop.const === "string") return [prop.const];
    if (typeof prop.default === "string") return [prop.default];
  }

  // Walk allOf members
  if (Array.isArray(schema.allOf)) {
    for (const member of schema.allOf) {
      const values = findDiscriminatorEnumValues(rootDoc, member, propName, visited);
      if (values.length) return values;
    }
  }

  return [];
}

/**
 * For every `oneOf` schema with a `discriminator.propertyName` but no explicit `discriminator.mapping`,
 * auto-populate the mapping by examining each oneOf member's discriminator property value.
 *
 * Why: swift-openapi-generator's discriminator decoding only matches schema names (e.g. `"FunctionTool"`)
 * against the wire-format discriminator value when no explicit mapping is provided. But OpenAI's APIs use
 * snake_case discriminator values (e.g. `"function"`) that differ from the schema names (`"FunctionTool"`),
 * so decoding fails at runtime with "unknownOneOfDiscriminator" or "keyNotFound" errors.
 *
 * This walks the entire spec, so it covers nested oneOf schemas (e.g. inside `properties`, `items`,
 * `requestBody.content`, response schemas) — not just top-level component schemas.
 */
function addOneOfDiscriminatorMappings(rootDoc) {
  function walk(node) {
    if (Array.isArray(node)) {
      for (const item of node) walk(item);
      return;
    }
    if (!node || typeof node !== "object") return;

    if (Array.isArray(node.oneOf) && node.discriminator?.propertyName && !node.discriminator.mapping) {
      const propName = node.discriminator.propertyName;
      const mapping = {};
      for (const member of node.oneOf) {
        if (!member?.$ref) continue;
        const resolved = resolveRef(rootDoc, member.$ref);
        if (!resolved) continue;
        const values = findDiscriminatorEnumValues(rootDoc, resolved, propName);
        for (const v of values) {
          // First mapping wins if duplicate values appear (shouldn't happen in practice).
          if (!(v in mapping)) mapping[v] = member.$ref;
        }
      }
      if (Object.keys(mapping).length > 0) {
        node.discriminator.mapping = mapping;
      }
    }

    for (const key of Object.keys(node)) {
      walk(node[key]);
    }
  }

  walk(rootDoc);
  return rootDoc;
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
openapiDoc = fixExclusiveMinMax(openapiDoc);
openapiDoc = convertNullable(openapiDoc);
openapiDoc = simplifyAnyOfNull(openapiDoc);
openapiDoc = fixDualContentType(openapiDoc);
openapiDoc = fixOptionalMultipartBodies(openapiDoc);
openapiDoc = removeNullOnlyProperties(openapiDoc);
openapiDoc = removeOrphanedRequired(openapiDoc);
openapiDoc = fixRecursiveRef(openapiDoc);
openapiDoc = fixMisplacedMinItems(openapiDoc);
openapiDoc = removeRequiredOnlyAnyOf(openapiDoc);
openapiDoc = fixAllOfOrphanedRequired(openapiDoc);
openapiDoc = fixArrayWithRequired(openapiDoc);
// addOneOfDiscriminatorMappings is intentionally not invoked: enabling it changes generated case
// names (e.g. `.FunctionTool` becomes `.function`), which is a breaking refactor for all existing
// call sites that construct these enums. Only enable when you're prepared to update those sites.
// openapiDoc = addOneOfDiscriminatorMappings(openapiDoc);

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
