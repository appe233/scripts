#!/bin/bash

# =================CONFIGURATION=================
TINIFY_KEY=""
SMMS_KEY=""

# Check for required dependencies
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed." >&2
    exit 1
fi

if [[ -z "$TINIFY_KEY" ]] || [[ -z "$SMMS_KEY" ]]; then
    echo "Error: API keys are missing. Please set TINIFY_API_KEY and API_KEY." >&2
    exit 1
fi
# ===============================================

# Create a temporary directory for this run
WORK_DIR=$(mktemp -d)

# cleanup function to run on exit or interrupt
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

for image in "$@"; do
    # 1. Validate Input
    if [[ ! -f "$image" ]]; then
        echo "Warning: File '$image' not found. Skipping." >&2
        continue
    fi

    echo "Processing: $image..." >&2

    # 2. Generate Hash for Filename (Preserving extension logic handled later)
    # handling shasum vs sha256sum portability
    if command -v shasum &> /dev/null; then
        HASH_NAME=$(shasum -a 256 "$image" | awk '{ print $1 }')
    else
        HASH_NAME=$(sha256sum "$image" | awk '{ print $1 }')
    fi

    # 3. Upload to Tinify (Shrink)
    # We capture the full JSON to check for errors
    TINIFY_RESPONSE=$(curl -s --user "api:$TINIFY_KEY" --data-binary "@$image" https://api.tinify.com/shrink)
    
    TINIFY_URL=$(echo "$TINIFY_RESPONSE" | jq -r ".output.url")
    
    if [[ "$TINIFY_URL" == "null" ]]; then
        echo "Error: Tinify compression failed for $image." >&2
        echo "Response: $TINIFY_RESPONSE" >&2
        continue
    fi

    # 4. Convert to WebP via Tinify (using the URL from step 3)
    # Tinify allows GETing the url to download, OR POSTing json to it to transform
    TEMP_WEBP="$WORK_DIR/$HASH_NAME.webp"
    
    curl -s "$TINIFY_URL" \
        --user "api:$TINIFY_KEY" \
        -H "Content-Type: application/json" \
        --data '{ "convert": { "type": "image/webp"} }' \
        -o "$TEMP_WEBP"

    if [[ ! -s "$TEMP_WEBP" ]]; then
        echo "Error: Failed to download converted WebP." >&2
        continue
    fi

    # 5. Upload to SM.MS
    # Note: SM.MS V2 API usage
    UPLOAD_RESPONSE=$(curl -s -X POST \
        -H "Authorization: $SMMS_KEY" \
        -F "smfile=@$TEMP_WEBP;type=image/webp;filename=$HASH_NAME.webp" \
        https://sm.ms/api/v2/upload)

    SUCCESS=$(echo "$UPLOAD_RESPONSE" | jq -r ".success")

    if [[ "$SUCCESS" == "true" ]]; then
        FINAL_URL=$(echo "$UPLOAD_RESPONSE" | jq -r ".data.url")
        # Output ONLY the URL to stdout so this script is pipeable
        echo "$FINAL_URL"
    elif [[ "$SUCCESS" == "false" ]]; then
        # Handle case where image already exists on SM.MS
        EXISTING_URL=$(echo "$UPLOAD_RESPONSE" | jq -r ".images" 2>/dev/null) 
        if [[ "$EXISTING_URL" != "null" && -n "$EXISTING_URL" ]]; then
             echo "$EXISTING_URL"
        else
             echo "Error: SM.MS Upload failed. $(echo "$UPLOAD_RESPONSE" | jq -r '.message')" >&2
        fi
    else
        echo "Error: Unknown response from SM.MS" >&2
    fi

done
