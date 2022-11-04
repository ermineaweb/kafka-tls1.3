#!/bin/bash

source env.sh

printf "Env variables:\nbroker: %s:%s\ntopic: %s\nconfig: %s\n\n" "$broker" "$port" "$topic" "$config"

# kafka needs zookeeper to sync all brokers
# we start zookeeper only if it is not running
if [ -z "$1" ]; then
    echo "Run only kafka"
    docker stop kafka-server
    sleep 2
else
    echo "Run zookeeper and kafka"
    docker stop $(docker ps -qf "name=^kafka-*")

    sleep 2

    docker run -d --rm \
    --net=host \
    --name kafka-zookeeper \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    bitnami/zookeeper:latest
    
    sleep 30
fi

SERVER_STORE=$(pwd)/cer-server
echo "import store $SERVER_STORE"

if [ "$config" = "ssl" ]; then
    docker run -d --rm \
    --net=host \
    --name kafka-server \
    -v "$SERVER_STORE"/kafka.keystore.jks:/opt/bitnami/kafka/config/certs/kafka.keystore.jks:ro \
    -v "$SERVER_STORE"/kafka.truststore.jks:/opt/bitnami/kafka/config/certs/kafka.truststore.jks:ro \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT=localhost:2181 \
    -e KAFKA_CFG_ZOOKEEPER_PROTOCOL=PLAINTEXT \
    -e KAFKA_CFG_SSL_KEYSTORE_LOCATION=/opt/bitnami/kafka/config/certs/kafka.keystore.jks \
    -e KAFKA_CFG_SSL_KEYSTORE_PASSWORD=secret \
    -e KAFKA_CFG_SSL_KEY_PASSWORD=secret \
    -e KAFKA_CFG_SSL_TRUSTSTORE_LOCATION=/opt/bitnami/kafka/config/certs/kafka.truststore.jks \
    -e KAFKA_CFG_SSL_TRUSTSTORE_PASSWORD=secret \
    -e KAFKA_SECURITY_PROTOCOL=SSL \
    -e KAFKA_CFG_LISTENERS=CLIENT://:9093,EXTERNAL://:"$port" \
    -e KAFKA_CFG_ADVERTISED_LISTENERS=CLIENT://localhost:9093,EXTERNAL://"$broker":"$port" \
    -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CLIENT:PLAINTEXT,EXTERNAL:SSL,SSL:SSL,PLAINTEXT:PLAINTEXT \
    -e KAFKA_SECURITY_INTER_BROKER_PROTOCOL=CLIENT \
    -e KAFKA_CFG_INTER_BROKER_LISTENER_NAME=CLIENT \
    -e KAFKA_CFG_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM= \
    bitnami/kafka:3.1.0

elif [ "$config" = "nossl" ]; then
    docker run -d --rm \
    --net=host \
    --name kafka-server \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT=localhost:2181 \
    bitnami/kafka:3.1.0
fi

