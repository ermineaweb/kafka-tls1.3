#!/bin/bash

source ../env.sh
printf "Env variables:\nbroker: %s:%s\ntopic: %s\nconfig: %s\n\n" "$broker" "$port" "$topic" "$config"

BASE_IMAGE="alpine:3.15.0"
printf "Setup the Dockerfile from %s\n" "$BASE_IMAGE"

cat > Dockerfile <<- EOF
FROM ${BASE_IMAGE}

RUN apk add --update --no-cache \
	bash \
	kafkacat

WORKDIR /app

COPY kcat/consumer.sh kcat/producer.sh kcat/*.conf ./
RUN chmod +x consumer.sh producer.sh

COPY cer-client/ cer-common/ cer/

ENV broker=$broker:$port
ENV topic=$topic
ENV config=$config.conf

ENTRYPOINT ["bash"]
EOF

printf "Build image\n"
IMAGE=$(docker build -q ../ -f ./Dockerfile)

docker run -it --rm \
	--net=host \
	"$IMAGE"