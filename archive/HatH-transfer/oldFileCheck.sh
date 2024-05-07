#!/bin/bash

for filedir in $(find ./cache/ -type f)
do
    filename=$(basename "$filedir")
    filesha=$(echo "$filename" | awk -F '-' '{print $1}')
    shasum=$(sha1sum "./$filedir" | awk '{print $1}')
    if [ "$filesha" == "$shasum" ]
    then
        echo "File $filesha is correct"
    else
        echo "File $filedir is corrupted"
        echo "$filedir" >> doNotUpload.list
    fi
done