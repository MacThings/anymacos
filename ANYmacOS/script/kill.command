#!/bin/bash

user=$( id -un )

temp_path="/private/tmp/anymacos_$user"


for KILLPID in `ps ax | grep 'aria' | awk ' { print $1;}'`; do
    kill -term $KILLPID;
done

for KILLPID in `ps ax | grep 'anymacos' | awk ' { print $1;}'`; do
    kill -term $KILLPID;
done

pkill -f script.command
    
    #rm "$temp_path"/files
