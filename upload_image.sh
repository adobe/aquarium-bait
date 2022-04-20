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
#   ./upload_image.sh [login:token] <out/image.tar.xz> [...]

[ "$ARTIFACT_STORAGE_AUTH" ] || ARTIFACT_STORAGE_AUTH=$1
[ "$ARTIFACR_STORAGE_URL" ] || ARTIFACT_STORAGE_URL=https://artofact-storage/aquarium/image

for path in "$@"; do
    # Skipping non-file target
    [ -f "${path}" ] || continue

    name=$(basename "$path" | rev | cut -d- -f2- | rev)
    echo "INFO: Processing $name"

    echo "INFO:  validating image ..."
    noext_name=$(basename "$path" | sed 's/\.t.*$//')
    if ! tar -tf "$path" "$noext_name/$noext_name.sha256" > /dev/null 2>&1; then
        echo "ERROR: The image archive is invalid because doesn't contain the required checksum file"
        exit 1
    fi

    echo "INFO:  calcuating checksum ..."
    checksum=$(sha256sum "$path" | cut -d' ' -f1)

    url="$ARTIFACT_STORAGE_URL/$name/$(basename $path)"
    echo "INFO:  uploading to $url ..."
    curl --progress-bar -u "$ARTIFACT_STORAGE_AUTH" -X PUT -H "X-Checksum-Sha256: $checksum" -T "$path" "$url" | tee /dev/null

    echo
    echo "INFO:  upload complete:"
    echo
    echo "INFO:  - name: \"$name\""
    echo "INFO:    url: \"$url\""
    echo "INFO:    checksum: \"sha256:$checksum\""
    echo
done

echo "INFO: Upload operation done"
