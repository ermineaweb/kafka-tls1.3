#!/bin/bash

count=3

while ((count > 0))
do
    printf -v date '%(%H:%M:%S)T' -1 
    printf -v message "message n°%s - %s" "$count" "$date"
    printf "topic '%s'\n'%s'\n" "$topic" "$message"
    printf "%s" "$message" | kcat -F "$config" -P -p key1 -t "$topic" -b "$broker"
    ((count--))
    sleep 5
done

