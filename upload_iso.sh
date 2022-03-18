#!/bin/sh -e
# Upload the installer iso
# Usage:
#   ./upload_image.sh [login:token] <iso/cd_dvd.iso> [...]

[ "$ARTIFACT_STORAGE_AUTH" ] || ARTIFACT_STORAGE_AUTH=$1
[ "$ARTIFACT_STORAGE_URL" ] || ARTIFACT_STORAGE_URL=https://artifact-storage/aquarium/installer

for path in "$@"; do
    # Skipping non-file target
    [ -f "${path}" ] || continue

    name=$(basename "$path" | rev | cut -d- -f2- | rev)
    echo "INFO: Processing $name"

    echo "INFO:  validating iso ..."
    if ! echo "${path}" | grep -q '.iso$' ; then
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
