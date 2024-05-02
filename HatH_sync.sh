#!/bin/bash

remoteHost="US_HentaiAtHome_ByteVirt_47323"

if [ ! -s filelist.txt ]
then
    rm -rvf filelist.txt incorrectfilelist.txt
    cd cache || exit
    find ./ -type d -empty -delete
    find ./ -type d -empty -delete

    for  dir1 in *
    do
        for dir2 in "$dir1"/*
        do
            for filedir in "$dir2"/*
            do
                filename=$(basename "$filedir")
                filesha=$(echo "$filename" | awk -F '-' '{print $1}')
                shasum=$(sha1sum "./$filedir" | awk '{print $1}')
                if [ "$shasum" == "$filesha" ]
                then
                    echo "$filedir" >> ../filelist.txt
                else
                    echo "$filedir" >> ../incorrectfilelist.txt
                    echo "$filedir is bad"
                fi
            done
        done
    done
    cd ../
fi

while true
do
    start=$(date +%s)

    ssh "$remoteHost" "
    mkdir -p cache
    cd cache

    find ./ -type d -empty -delete
    find ./ -type d -empty -delete

    for  dir1 in *
    do
        for dir2 in \"\$dir1\"/*
        do
            for filedir in \"\$dir2\"/*
            do
                filename=\$(basename \"\$filedir\")
                filesha=\$(echo \"\$filename\" | awk -F '-' '{print \$1}')
                shasum=\$(sha1sum \"./\$filedir\" | awk '{print \$1}')
                if [ \"\$shasum\" == \"\$filesha\" ]
                then
                    echo \"\$filedir\"
                else
                    rm -rf \"\$filedir\"
                fi
            done
        done
    done
    " > remotefilelist.txt

    rm -rvf needupload.txt
    cat filelist.txt remotefilelist.txt remotefilelist.txt | sort | uniq -u > needupload.txt

    if [ ! -s needupload.txt ]
    then
        break
    fi

    tar c -T needupload.txt | ssh "$remoteHost" "cd cache && tar xv"

    loopend=$(date +%s)
    if [ $((loopend - start)) -lt 600 ]
    then
        echo "sleeping"
        sleep $((600 - loopend + start))
    fi
done
