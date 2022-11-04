#!/bin/bash

printf "create topic\nbroker: %s\ntopic: %s\nconfig: %s\n\n" $broker $topic $config

kafka-topics.sh \
--create \
--topic "$topic" \
--bootstrap-server "$broker" \
--command-config "$config"

printf "list topics\nbroker: %s\ntopic: %s\nconfig: %s\n\n" $broker $topic $config

kafka-topics.sh \
--list \
--bootstrap-server "$broker" \
--command-config "$config"