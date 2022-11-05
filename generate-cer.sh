#!/bin/bash

source env.sh

LOCAL_DIR=$(pwd)
COMMON_DIR="cer-common"
CLIENT_DIR="cer-client"
SERVER_DIR="cer-server"

# force mode for CI
if [ "$1" = "-y" ] ; then
  sudo rm -R cer-*
fi

if [ -e "$COMMON_DIR" ] || [ -e "$CLIENT_DIR" ] || [ -e "$SERVER_DIR" ]; then
  read -r -p "Certificate directories already exist. They will be override, continue? (y/n) " resp
  if [ "$resp" = "y" ]; then
    sudo rm -R cer-*
  else
    echo "Aborting the certificates creation."
    exit 1
  fi
fi

mkdir -p "$COMMON_DIR" "$CLIENT_DIR" "$SERVER_DIR"

SECRET="secret"
SUBJ="/C=fr/ST=fr/L=fr/O=society/OU=society/CN=$broker/emailAddress=mail@society.com"
printf "Broker: %s\n" "$broker"

# Common
printf "\e[1;36m%s\e[0;00m\n" "Common - Generate CA certificate and its key"
docker run \
-v "$LOCAL_DIR"/"$COMMON_DIR":/"$COMMON_DIR" \
--user "$(id -u "$USER")" \
--entrypoint openssl \
bitnami/kafka:3.1.0 \
req -new -x509 -days 3650 \
-keyout /"$COMMON_DIR"/ca-key \
-out /"$COMMON_DIR"/ca-cert  \
-subj "$SUBJ" \
-passin "pass:$SECRET" \
-passout "pass:$SECRET"

# Client
printf "\e[1;36m%s\e[0;00m\n" "Client - Generate request certificate and its key"
docker run \
-v "$LOCAL_DIR"/"$CLIENT_DIR":/"$CLIENT_DIR" \
--user "$(id -u "$USER")" \
--entrypoint openssl \
bitnami/kafka:3.1.0 \
req -new \
-keyout "$CLIENT_DIR"/cert-key \
-out "$CLIENT_DIR"/cert-file \
-subj "$SUBJ" \
-passin "pass:$SECRET" \
-passout "pass:$SECRET"

printf "\e[1;36m%s\e[0;00m\n" "Client - Sign certificate with the CA"
docker run \
-v "$LOCAL_DIR"/"$CLIENT_DIR":/"$CLIENT_DIR" \
-v "$LOCAL_DIR"/"$COMMON_DIR":/"$COMMON_DIR" \
--user "$(id -u "$USER")" \
--entrypoint openssl \
bitnami/kafka:3.1.0 \
x509 -req -days 365 \
-CA "$COMMON_DIR"/ca-cert \
-CAkey "$COMMON_DIR"/ca-key \
-in "$CLIENT_DIR"/cert-file \
-out "$CLIENT_DIR"/cert-signed \
-CAcreateserial \
-passin "pass:$SECRET"

# Server
printf "\e[1;36m%s\e[0;00m\n" "Server - Generate key and certificate for each broker"
docker run \
-v "$LOCAL_DIR"/"$SERVER_DIR":/"$SERVER_DIR" \
--user "$(id -u "$USER")" \
--entrypoint keytool \
bitnami/kafka:3.1.0 \
-genkey -noprompt -alias localhost -keyalg RSA \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-dname "CN=$broker, OU=society O=society, L=fr, ST=fr, C=fr" \
-storepass "$SECRET" \
-keypass "$SECRET"

printf "\e[1;36m%s\e[0;00m\n" "Server - Add the generated CA to the broker and client truststores"
docker run \
-v "$LOCAL_DIR"/"$SERVER_DIR":/"$SERVER_DIR" \
-v "$LOCAL_DIR"/"$COMMON_DIR":/"$COMMON_DIR" \
--user "$(id -u "$USER")" \
--entrypoint keytool \
bitnami/kafka:3.1.0 \
-import -noprompt -alias CA"$USER" \
-keystore "$SERVER_DIR"/kafka.truststore.jks \
-file "$COMMON_DIR"/ca-cert \
-storepass "$SECRET"

printf "\e[1;36m%s\e[0;00m\n" "Server - Export the certificate from the keystore"
docker run \
-v "$LOCAL_DIR"/"$SERVER_DIR":/"$SERVER_DIR" \
--user "$(id -u "$USER")" \
--entrypoint keytool \
bitnami/kafka:3.1.0 \
-certreq -alias localhost \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-file "$SERVER_DIR"/cert-file \
-storepass "$SECRET"

printf "\e[1;36m%s\e[0;00m\n" "Server - Sign certificate with the CA"
docker run \
-v "$LOCAL_DIR"/"$SERVER_DIR":/"$SERVER_DIR" \
-v "$LOCAL_DIR"/"$COMMON_DIR":/"$COMMON_DIR" \
--user "$(id -u "$USER")" \
--entrypoint openssl \
bitnami/kafka:3.1.0 \
x509 -req -days 365 \
-CA "$COMMON_DIR"/ca-cert \
-CAkey "$COMMON_DIR"/ca-key \
-in "$SERVER_DIR"/cert-file \
-out "$SERVER_DIR"/cert-signed \
-CAcreateserial \
-passin "pass:$SECRET"

printf "\e[1;36m%s\e[0;00m\n" "Server- Import both the CA and the signed certificate into the broker keystore"
docker run \
-v "$LOCAL_DIR"/"$SERVER_DIR":/"$SERVER_DIR" \
-v "$LOCAL_DIR"/"$COMMON_DIR":/"$COMMON_DIR" \
--user "$(id -u "$USER")" \
--entrypoint keytool \
bitnami/kafka:3.1.0 \
-import -noprompt -alias CA"$USER" \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-file "$COMMON_DIR"/ca-cert \
-storepass "$SECRET"

docker run \
-v "$LOCAL_DIR"/"$SERVER_DIR":/"$SERVER_DIR" \
--user "$(id -u "$USER")" \
--entrypoint keytool \
bitnami/kafka:3.1.0 \
-import -noprompt -alias localhost \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-file "$SERVER_DIR"/cert-signed \
-storepass "$SECRET"