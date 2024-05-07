#!/bin/bash

remoteHost="US_HentaiAtHome_ByteVirt_47323"

find ./cache/ -type f > ./localFiles.list

while true
do
    ssh "$remoteHost" "
    mkdir -p cache
    find ./cache/ -type f
    " > ./remoteFiles.list

    rm -rvf ./uploadFiles.list
    touch ./doNotUpload.list
    cat ./localFiles.list ./remoteFiles.list ./remoteFiles.list doNotUpload.list doNotUpload.list | sort | uniq -u > ./uploadFiles.list

    tar c -T uploadFiles.list | ssh "$remoteHost" "tar xv"

    if [ -s needupload.txt ]
    then
        stop=0
    else
        stop=$((stop+1))
    fi
    if [ "$stop" -gt 10 ]
    then
        ssh "$remoteHost" "echo 'true' > ./Finish.txt"
        break
    fi
done