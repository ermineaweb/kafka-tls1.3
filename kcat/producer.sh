#!/bin/bash

while true
do
    read -p "> " message
    printf "%s" "$message" | kcat -F "$config" -P -p key1 -t "$topic" -b "$broker"
done

