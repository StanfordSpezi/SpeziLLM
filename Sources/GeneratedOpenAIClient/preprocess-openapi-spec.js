//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

// Prepares the upstream OpenAI OpenAPI document for swift-openapi-generator.
//
// The upstream document is written for OpenAI's documentation tooling rather than for code generators: it mixes
// OpenAPI 3.0 and 3.1 spellings, carries constraints that no static type system can express, and leaves
// discriminated unions without the mapping a decoder needs. Every transform below is a general rule, applied to the
// whole document, rather than a patch for one named schema, so re-running the script on a newer upstream revision
// needs no changes here.
//
// Usage: `npm run update` fetches the latest upstream document and preprocesses it, `npm run preprocess` only
// preprocesses the document already on disk. See README.md.

const fs = require("fs");
const yaml = require("js-yaml");

const openapiPath = process.env.npm_package_config_openapiFile ?? "openapi.yaml";

const header = `#
# This source file is part of the Stanford Spezi open source project.
# It is based on the official OpenAI OpenAPI spec with modifications by the Spezi project authors: https://github.com/openai/openai-openapi/blob/main/openapi.yaml
#
# SPDX-FileCopyrightText: 2024 Stanford University, OpenAI, and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

`;

// MARK: - Helpers

const SCHEMA_REF_PREFIX = "#/components/schemas/";

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

/// Whether a schema node stands for the JSON `null` type and nothing else.
function isNullSchema(schema) {
  return isObject(schema) && schema.type === "null" && Object.keys(schema).every((key) => key === "type" || key === "description");
}

/// Calls `visit(node)` for every object in the document, children before parents.
function walk(node, visit) {
  if (Array.isArray(node)) {
    node.forEach((item) => walk(item, visit));
  } else if (isObject(node)) {
    Object.values(node).forEach((value) => walk(value, visit));
    visit(node);
  }
}

/// Calls `visit(node)` for every object in the document, parents before children.
function walkPreOrder(node, visit) {
  if (Array.isArray(node)) {
    node.forEach((item) => walkPreOrder(item, visit));
  } else if (isObject(node)) {
    visit(node);
    Object.values(node).forEach((value) => walkPreOrder(value, visit));
  }
}

/// Resolves a local `$ref` such as `#/components/schemas/Foo` to the referenced node.
function resolveRef(doc, ref) {
  if (typeof ref !== "string" || !ref.startsWith("#/")) {
    return undefined;
  }
  return ref
    .slice(2)
    .split("/")
    .reduce((node, segment) => (isObject(node) ? node[segment] : undefined), doc);
}

// MARK: - Transforms

/**
 * Removes everything marked `deprecated`, along with any `$ref` that pointed at a removed schema.
 *
 * Deprecated operations, schemas, and properties would otherwise be generated with a deprecation attribute, and
 * every use of them inside the generated client would warn.
 */
function removeDeprecated(doc) {
  const removedSchemaRefs = new Set(
    Object.entries(doc.components?.schemas ?? {})
      .filter(([, schema]) => isObject(schema) && schema.deprecated === true)
      .map(([name]) => SCHEMA_REF_PREFIX + name)
  );

  function isRemoved(node) {
    return isObject(node) && (node.deprecated === true || removedSchemaRefs.has(node.$ref));
  }

  function strip(node) {
    if (Array.isArray(node)) {
      return node.filter((item) => !isRemoved(item)).map(strip);
    }
    if (!isObject(node)) {
      return node;
    }
    const result = {};
    for (const [key, value] of Object.entries(node)) {
      if (!isRemoved(value)) {
        result[key] = strip(value);
      }
    }
    return result;
  }

  return strip(doc);
}

/**
 * Rewrites OpenAPI 3.0 boolean `exclusiveMinimum`/`exclusiveMaximum` into the 3.1 numeric form.
 *
 * The document declares itself as 3.1, where these keywords carry the bound itself; a boolean is rejected by the
 * generator's parser.
 */
function normalizeExclusiveBounds(node) {
  for (const [exclusive, inclusive] of [["exclusiveMinimum", "minimum"], ["exclusiveMaximum", "maximum"]]) {
    if (typeof node[exclusive] !== "boolean") {
      continue;
    }
    if (node[exclusive] && node[inclusive] !== undefined) {
      node[exclusive] = node[inclusive];
      delete node[inclusive];
    } else {
      delete node[exclusive];
    }
  }
}

/**
 * Rewrites `$recursiveRef: "#"` into a plain `$ref` to the component schema it appears in.
 *
 * The keyword comes from JSON Schema draft 2019-09, which the generator does not read; inside a component schema it
 * means the schema itself, which a regular reference expresses just as well.
 */
function resolveRecursiveReferences(doc) {
  for (const [name, schema] of Object.entries(doc.components?.schemas ?? {})) {
    walk(schema, (node) => {
      delete node.$recursiveAnchor;
      if (node.$recursiveRef === "#") {
        delete node.$recursiveRef;
        node.$ref = SCHEMA_REF_PREFIX + name;
      }
    });
  }
}

/**
 * Collapses every spelling of "this value may be null" into a plain, non-null schema.
 *
 * The document uses all three: the 3.0 `nullable: true`, the 3.1 `type: [T, "null"]`, and `anyOf`/`oneOf` with a
 * `{type: "null"}` branch. The generator turns the union spellings into wrapper types with one optional field per
 * branch, which makes every nullable field awkward to use. Swift expresses nullability with an optional at the use
 * site instead, so the null branch is dropped here and, where the schema is a property, the property is removed
 * from its parent's `required` list by ``normalizeRequired``.
 *
 * - Returns: `true` if the schema admitted `null`.
 */
function stripNull(schema) {
  let wasNullable = false;

  if (schema.nullable === true) {
    wasNullable = true;
  }
  delete schema.nullable;

  if (Array.isArray(schema.type)) {
    const types = schema.type.filter((type) => type !== "null");
    wasNullable ||= types.length !== schema.type.length;
    if (types.length === 1) {
      schema.type = types[0];
    } else if (types.length === 0) {
      delete schema.type;
    } else {
      schema.type = types;
    }
  }

  for (const keyword of ["anyOf", "oneOf"]) {
    if (!Array.isArray(schema[keyword])) {
      continue;
    }
    const branches = schema[keyword].filter((branch) => !isNullSchema(branch));
    if (branches.length === schema[keyword].length) {
      continue;
    }
    wasNullable = true;
    if (branches.length === 0) {
      // Nothing but `null` was left, typically because the other branch was deprecated: any value is accepted.
      delete schema[keyword];
    } else if (branches.length === 1) {
      // A single remaining branch is the schema itself; its own keywords win over the wrapper's.
      delete schema[keyword];
      Object.assign(schema, branches[0]);
    } else {
      schema[keyword] = branches;
    }
  }

  if (wasNullable) {
    if (Array.isArray(schema.enum)) {
      schema.enum = schema.enum.filter((value) => value !== null);
    }
    if (schema.default === null) {
      delete schema.default;
    }
  }
  return wasNullable;
}

/// Whether a schema admits `null` in any of the spellings ``stripNull`` understands.
function admitsNull(schema) {
  return (
    schema.nullable === true ||
    (Array.isArray(schema.type) && schema.type.includes("null")) ||
    ["anyOf", "oneOf"].some((keyword) => Array.isArray(schema[keyword]) && schema[keyword].some(isNullSchema))
  );
}

/// The names of the properties that were nullable, recorded on the object so ``normalizeRequired`` can see them.
const NULLABLE_PROPERTIES = Symbol("nullableProperties");

/**
 * Applies ``stripNull`` to every schema, remembering which properties were nullable.
 *
 * Visits parents first, so that an object still sees which of its properties admit `null`. A property that only
 * references a component schema is nullable when that schema is, which is why the nullable component schemas are
 * collected before anything is stripped.
 */
function normalizeNullability(doc) {
  const nullableSchemaRefs = new Set(
    Object.entries(doc.components?.schemas ?? {})
      .filter(([, schema]) => isObject(schema) && admitsNull(schema))
      .map(([name]) => SCHEMA_REF_PREFIX + name)
  );

  walkPreOrder(doc, (node) => {
    if (isObject(node.properties)) {
      const nullable = [];
      for (const [name, property] of Object.entries(node.properties)) {
        if (!isObject(property)) {
          continue;
        }
        const referencesNullable = nullableSchemaRefs.has(property.$ref);
        if (stripNull(property) || referencesNullable) {
          nullable.push(name);
        }
      }
      node[NULLABLE_PROPERTIES] = nullable;
    }
    stripNull(node);
  });
}

/**
 * Keeps `required` truthful: it may only name properties that exist on the same object, and never a nullable one.
 *
 * The document lists properties as required that are defined on a sibling `allOf` member, that were removed as
 * deprecated, or that do not exist at all. The generator treats each object on its own, so such an entry makes it
 * look for a property it cannot find. A nullable property is dropped because the API does send `null` for it, and
 * a non-optional Swift property cannot hold that.
 */
function normalizeRequired(node) {
  const nullable = new Set(node[NULLABLE_PROPERTIES] ?? []);
  delete node[NULLABLE_PROPERTIES];
  if (!Array.isArray(node.required)) {
    return;
  }
  const properties = isObject(node.properties) ? node.properties : {};
  node.required = node.required.filter((name) => name in properties && !nullable.has(name));
  if (node.required.length === 0) {
    delete node.required;
  }
}

/**
 * Drops composition constraints that only express which keys must be present.
 *
 * An `anyOf`/`oneOf` whose branches consist of nothing but `required` lists says "at least/exactly one of these
 * properties", which a static type cannot express. The generator would instead emit one empty type per branch.
 */
function removeKeyPresenceConstraints(node) {
  for (const keyword of ["anyOf", "oneOf"]) {
    const branches = node[keyword];
    if (!Array.isArray(branches) || branches.length === 0) {
      continue;
    }
    const onlyRequired = branches.every((branch) => isObject(branch) && Object.keys(branch).length === 1 && Array.isArray(branch.required));
    if (onlyRequired) {
      delete node[keyword];
      if (isObject(node.not) && Array.isArray(node.not.required)) {
        delete node.not;
      }
    }
  }
}

/**
 * Moves array keywords that ended up on an array's `items` back onto the array.
 *
 * `minItems`/`maxItems` describe the array, not its elements; the document occasionally attaches them to a string
 * element schema, where the generator rejects them.
 */
function hoistArrayConstraints(node) {
  if (node.type !== "array" || !isObject(node.items)) {
    return;
  }
  for (const keyword of ["minItems", "maxItems"]) {
    if (node.items[keyword] !== undefined) {
      node[keyword] ??= node.items[keyword];
      delete node.items[keyword];
    }
  }
}

/**
 * Fills in the `discriminator.mapping` of every `oneOf` that declares a discriminator without one.
 *
 * Without a mapping, the OpenAPI specification says the discriminator value is the schema's name, and the generator
 * decodes accordingly. OpenAI's unions send a `type` such as `function` for a schema named `FunctionTool`, so every
 * value fails to decode. The mapping is derived from the `enum` (or `const`/`default`) the discriminator property
 * declares on each branch. A union is left untouched when a branch is not a named schema or declares no value,
 * because a partial mapping would reject the unmapped branches outright. When two branches declare the same value,
 * the first one keeps it.
 */
function deriveDiscriminatorMappings(doc) {
  function discriminatorValues(schema, property, visited = new Set()) {
    if (!isObject(schema)) {
      return [];
    }
    if (schema.$ref) {
      if (visited.has(schema.$ref)) {
        return [];
      }
      visited.add(schema.$ref);
      return discriminatorValues(resolveRef(doc, schema.$ref), property, visited);
    }
    const declaration = schema.properties?.[property];
    if (isObject(declaration)) {
      if (Array.isArray(declaration.enum) && declaration.enum.length > 0) {
        return declaration.enum.map(String);
      }
      if (typeof declaration.const === "string") {
        return [declaration.const];
      }
      if (typeof declaration.default === "string") {
        return [declaration.default];
      }
    }
    for (const member of schema.allOf ?? []) {
      const values = discriminatorValues(member, property, visited);
      if (values.length > 0) {
        return values;
      }
    }
    return [];
  }

  walk(doc, (node) => {
    if (!Array.isArray(node.oneOf) || !isObject(node.discriminator) || node.discriminator.mapping) {
      return;
    }
    const property = node.discriminator.propertyName;
    const mapping = {};
    for (const branch of node.oneOf) {
      if (!isObject(branch) || typeof branch.$ref !== "string") {
        return;
      }
      const values = discriminatorValues(branch, property);
      if (values.length === 0) {
        return;
      }
      for (const value of values) {
        mapping[value] ??= branch.$ref;
      }
    }
    node.discriminator.mapping = mapping;
  });
}

/**
 * Removes the `webhooks` section.
 *
 * The generator produces nothing for webhooks, but every reference in the document still has to resolve, and
 * filtering keeps only the components that the selected operations reach. A webhook's request body would then
 * point at a schema that is no longer there.
 */
function removeWebhooks(doc) {
  delete doc.webhooks;
}

// MARK: - Pipeline

let doc = yaml.load(fs.readFileSync(openapiPath, "utf8"));

doc = removeDeprecated(doc);
removeWebhooks(doc);
resolveRecursiveReferences(doc);
walk(doc, normalizeExclusiveBounds);
normalizeNullability(doc);
walk(doc, normalizeRequired);
walk(doc, removeKeyPresenceConstraints);
walk(doc, hoistArrayConstraints);
deriveDiscriminatorMappings(doc);

const output = yaml.dump(doc, {
  sortKeys: false, // Preserve key order
  lineWidth: 0, // Prevent automatic line wrapping
  noCompatMode: true, // Ensure modern YAML 1.2+ behavior
  quotingType: '"', // Use double quotes for strings
  forceQuotes: false, // Do not force unnecessary quotes
  indent: 2, // Use consistent 2-space indentation
  skipInvalid: true, // Prevent errors due to unknown types
  styles: { "!!str": "folded" }, // Preserve multi-line string formatting
});

fs.writeFileSync(openapiPath, header + output, "utf8");

console.log("✅ Successfully preprocessed OpenAPI spec and prepended Spezi copyright header.");
