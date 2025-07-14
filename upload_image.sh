#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Upload the image
# Usage:
#   ./upload_image.sh [login:token] <out/type/image.tar.xz> [...]

if [ -z "$ARTIFACT_STORAGE_AUTH" ]; then
    ARTIFACT_STORAGE_AUTH="$1"
    shift
fi
[ "$ARTIFACT_STORAGE_URL" ] || ARTIFACT_STORAGE_URL=https://artifact-storage/aquarium/image

for path in "$@"; do
    if [ ! -f "$path" ]; then
        echo "WARNING: Skipping $f - does not exist"
        continue
    fi

    name=$(basename "$path" | rev | cut -d- -f2- | rev)
    type=$(basename "$(dirname "$path")")
    echo "INFO: Processing $name"

    echo "INFO:  validating image ..."
    noext_name=$(basename "$path" | sed 's/\.t.*$//')
    if ! tar -tf "$path" "$noext_name/$noext_name.sha256" > /dev/null 2>&1; then
        echo "ERROR: The image archive is invalid because doesn't contain the required checksum file"
        exit 1
    fi

    echo "INFO:  calcuating checksum ..."
    # MacOS doesn't have sha256sum command
    if ! command -v sha256sum > /dev/null; then alias sha256sum="shasum -a 256 -b"; fi
    checksum=$(sha256sum "$path" | cut -d' ' -f1)

    url="$ARTIFACT_STORAGE_URL/$type/$name/$(basename $path)"
    echo "INFO:  uploading to $url ..."
    curl --progress-bar -u "$ARTIFACT_STORAGE_AUTH" -X PUT -H "X-Checksum-Sha256: $checksum" -T "$path" "$url" | tee /dev/null

    echo
    echo "INFO:  upload complete:"
    echo
    echo "INFO:  - name: $name"
    echo "INFO:    url: $url"
    echo "INFO:    sum: sha256:$checksum"
    echo
done

echo "INFO: Upload operation done"
