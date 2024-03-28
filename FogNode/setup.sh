#!/bin/bash

#
# This source file is part of the Stanford Spezi open source project
#
# SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#

cd certs

# Issue the custom root CA certificate with a passphrase for the private key
openssl req -new -x509 -days 3650 -keyout ca/ca.key -out ca/ca.crt -subj "/CN=SpeziLLMFog CA" -passout pass:SpeziLLMFogPassword

# Create the web service key
openssl genrsa -out webservice/spezillmfog.local.key 2048

# Generate a signing request for the web service key
openssl req -new -key webservice/spezillmfog.local.key -out webservice/spezillmfog.local.csr -config openssl.cnf

# Sign the web service key with the CA certificate, using the CA's passphrase to access the private
openssl x509 -req -in webservice/spezillmfog.local.csr -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial -out webservice/spezillmfog.local.crt -days 365 -sha256 -extfile openssl.cnf -extensions v3_ca -passin pass:SpeziLLMFogPassword

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

echo ""
echo "${GREEN}Success: The root CA certificate as well as the webservice certificate were sucessfully issued.${RESET}"
echo "${RED}Warning: Issue the Firebase Admin Service Account key via the Firebase Console and place it within the 'auth' directory under the name 'serviceAccountKey.json', if not using the Firebase Emulator.${RESET}"
