#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2024 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

#!/bin/bash

# Default file names
INPUT_FILE=${1:-openapi.yaml}
OUTPUT_FILE=${2:-openapi.yaml}

# Function for error messages and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Check if the input file exists
[ -f "$INPUT_FILE" ] || error_exit "Input OpenAPI spec '$INPUT_FILE' not found."

# Ensure the output file is writable (or can be created)
[ ! -e "$OUTPUT_FILE" ] || [ -w "$OUTPUT_FILE" ] || error_exit "Output OpenAPI spec '$OUTPUT_FILE' is not writable."

# Create a temporary file
TMP_FILE=$(mktemp) || error_exit "Failed to create temporary file."

# Remove 'deprecated: true' lines and ONLY the exact "oneOf" block
sed -E '/^[[:space:]]*deprecated:[[:space:]]*true[[:space:]]*$/d' "$INPUT_FILE" | \
sed -E '/^[[:space:]]{14}oneOf:/ {
  N
  /[[:space:]]{16}- required:/ {
    N
    /[[:space:]]{20}- vector_store_ids/ {
      N
      /[[:space:]]{16}- required:/ {
        N
        /[[:space:]]{20}- vector_stores/ d
      }
    }
  }
}' > "$TMP_FILE" || error_exit "Failed to process OpenAPI YAML file."

# Move the cleaned temporary file to the output file
mv "$TMP_FILE" "$OUTPUT_FILE" || error_exit "Failed to overwrite the output file."

echo "Successfully cleaned the OpenAPI spec. Saved to '$OUTPUT_FILE'."
exit 0
