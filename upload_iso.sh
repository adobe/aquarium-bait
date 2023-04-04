#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Upload the installer iso
# Usage:
#   ./upload_image.sh [login:token] <iso/cd_dvd.iso> [artifact_path]

[ "$ARTIFACT_STORAGE_AUTH" ] || ARTIFACT_STORAGE_AUTH="$1"
[ "$ARTIFACT_STORAGE_URL" ] || ARTIFACT_STORAGE_URL=https://artifact-storage/aquarium/installer

FILE_PATH="$2"
name=$(basename "$FILE_PATH" | rev | cut -d- -f2- | rev)

[ "$ARTIFACT_PATH" ] || ARTIFACT_PATH="$3"
[ "$ARTIFACT_PATH" ] || ARTIFACT_PATH="$name/$(basename "$FILE_PATH")"

# Skipping non-file target
[ -f "$FILE_PATH" ] || exit 1

name=$(basename "$FILE_PATH" | rev | cut -d- -f2- | rev)
echo "INFO: Processing $name"

echo "INFO:  validating iso ..."
if ! echo "${FILE_PATH}" | grep -q '.iso$' ; then
    echo "ERROR: The iso file is not ending .iso"
    exit 1
fi

echo "INFO:  calcuating checksum ..."
checksum=$(sha256sum "$FILE_PATH" | cut -d' ' -f1)

url="$ARTIFACT_STORAGE_URL/${ARTIFACT_PATH}"
echo "INFO:  uploading to $url ..."
curl --progress-bar -u "$ARTIFACT_STORAGE_AUTH" -X PUT -H "X-Checksum-Sha256: $checksum" -T "$FILE_PATH" "$url" | tee /dev/null

echo
echo "INFO:  upload complete:"
echo
echo "INFO:  - name: \"$name\""
echo "INFO:    url: \"$url\""
echo "INFO:    checksum: \"sha256:$checksum\""
echo

echo "INFO: Upload operation done"
