#!/bin/bash

printf "start kafka producer\nbroker: %s\ntopic: %s\nconfig: %s\n\n" $broker $topic $config

kafka-console-producer.sh \
--topic "$topic" \
--bootstrap-server "$broker" \
--producer.config "$config"