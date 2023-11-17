#!/bin/sh -e
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

# Upload all the following files to the specific URL
# Usage:
#   ./upload_file.sh <login:token> <UPLOAD_URL> [path/to/file] [...]

[ "$ARTIFACT_STORAGE_AUTH" ] || ARTIFACT_STORAGE_AUTH="$1"

UPLOAD_URL="$2"

for f in "$@"; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    echo "INFO: Processing $f"

    echo "INFO:  calcuating checksum ..."
    # MacOS doesn't have sha256sum command
    if ! command -v sha256sum > /dev/null; then alias sha256sum="shasum -a 256 -b"; fi
    checksum=$(sha256sum "$FILE_PATH" | cut -d' ' -f1)

    url="$UPLOAD_URL/$name"
    echo "INFO:  uploading to $url ..."
    curl --progress-bar -u "$ARTIFACT_STORAGE_AUTH" -X PUT -H "X-Checksum-Sha256: $checksum" -T "$FILE_PATH" "$url" | tee /dev/null

    echo
    echo "INFO:  upload complete:"
    echo
    echo "INFO:  - name: \"$name\""
    echo "INFO:    url: \"$url\""
    echo "INFO:    checksum: \"sha256:$checksum\""
    echo
done

echo "INFO: Upload operation done"
