#!/bin/bash

printf "start kafka consumer\nbroker: %s\ntopic: %s\nconfig: %s\n\n" $broker $topic $config

kcat -F "$config" -C -p key1 -t "$topic" -b "$broker"