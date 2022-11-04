#!/bin/bash

printf "start kafka consumer\nbroker: %s\ntopic: %s\nconfig: %s\n\n" $broker $topic $config

kafka-console-consumer.sh \
--topic "$topic" \
--bootstrap-server "$broker" \
--from-beginning \
--consumer.config "$config"