#!/bin/bash

printf "start kafka producer\nbroker: %s\ntopic: %s\nconfig: %s\n\n" $broker $topic $config

while true
do
    read -p "> " message
    printf "%s" "$message" | kcat -F "$config" -P -p key1 -t "$topic" -b "$broker"
done

