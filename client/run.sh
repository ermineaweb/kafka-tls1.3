#!/bin/bash

source ../env.sh
printf "Env variables:\nbroker: %s:%s\ntopic: %s\nconfig: %s\n\n" "$broker" "$port" "$topic" "$config"

BASE_IMAGE="bitnami/kafka:3.1.0"
printf "Setup the Dockerfile from %s\n" "$BASE_IMAGE"

cat > Dockerfile <<- EOF
FROM ${BASE_IMAGE}

WORKDIR /app

COPY client/consumer.sh client/producer.sh client/create-topic.sh client/*.conf ./

COPY cer-server/ cer/

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