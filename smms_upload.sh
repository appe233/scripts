#!/bin/zsh
# Use it with Typora + smms
# Rename pictures' names to be their hash
API_KEY="" # Enter your API key here
for image in $@
do
    HASH_NAME=$(shasum -b -a 256 $image | awk '{ print $1 }')
    SUFFIX=$(basename $image | grep -o "\.[a-z]\+")
    cp $image "/Users/appe/$HASH_NAME$SUFFIX"
    OUT=$(curl -s -X POST -H "Authorization: $API_KEY" -F "smfile=@/Users/appe/$HASH_NAME$SUFFIX" https://smms.app/api/v2/upload) && rm /Users/appe/$HASH_NAME$SUFFIX
    # echo $(echo "$OUT" | jq -r ".message")
    echo $(echo "$OUT" | /opt/homebrew/bin/jq -r ".data.url")
done
