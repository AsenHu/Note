#!/bin/bash

touch sha.cache Finish.txt

while true
do
    start=$(date +%s)
    cd ./cache || exit
    find ./ -type f > ../files.list
    cd ../

    for srtdir in $(cat ./files.list sha.cache sha.cache | sort | uniq -u)
    do
        dir="./cache/$srtdir"
        filename=$(basename "$dir")
        filesha=$(echo "$filename" | awk -F '-' '{print $1}')
        shasum=$(sha1sum "./$dir" | awk '{print $1}')
        if [ "$filesha" == "$shasum" ]
        then
            echo "$srtdir" >> sha.cache
            echo "File $filesha is correct"
        else
            rm -rvf "./$dir"
            echo "File $filesha is incorrect"
        fi
    done

    if [ "$(cat ./Finish.txt)" == true ]
    then
        break
    fi
    loopend=$(date +%s)
    if [ $((loopend-start)) -lt 60 ]
    then
        echo "Sleeping for $((60-(loopend-start))) seconds"
        sleep $((60-(loopend-start)))
    fi
done