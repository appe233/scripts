#!/bin/bash

TINIFY_API_KEY=""
API_KEY="" # Enter the API key here.


for image in $@
do
    HASH_NAME=$(shasum -b -a 256 $image | awk '{ print $1 }')

    TINIFY_URL=$(curl -s https://api.tinify.com/shrink --user "api:$TINIFY_API_KEY" --data-binary "@$image" | /opt/homebrew/bin/jq -r ".output.url")
    TEMP_FILE=$(mktemp)
    curl -s $TINIFY_URL --user "api:$TINIFY_API_KEY" -H "Content-Type: application/json" --data '{ "convert": { "type": "image/webp"} }' -o $TEMP_FILE $TINIFY_URL
    OUT=$(curl -s -X POST -H "Authorization: $API_KEY" -F "smfile=@$TEMP_FILE;type=image/webp;filename=$HASH_NAME.webp" https://sm.ms/api/v2/upload | /opt/homebrew/bin/jq -r ".data.url") 
    echo $OUT
done
