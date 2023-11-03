#!/bin/bash
# Use it with Typora
API_KEY="" # Enter the API key here.
for image in $@
do
    OUT=$(curl -s -X POST -H "Authorization: $API_KEY" -F "smfile=@$image" https://sm.ms/api/v2/upload)
    echo echo $(echo "$OUT" | jq -r ".message")
    echo $(echo "$OUT" | jq -r ".data.url")
done
