#!/bin/bash

source env.sh

printf "Env variables:\nbroker: %s\n" "$broker"

COMMON_DIR="cer-common"
CLIENT_DIR="cer-client"
SERVER_DIR="cer-server"

SECRET="secret"

SUBJ="/C=fr/ST=fr/L=fr/O=society/OU=society/CN=$broker/emailAddress=mail@society.com"

if [ -e "$COMMON_DIR" ] || [ -e "$CLIENT_DIR" ] || [ -e "$SERVER_DIR" ]; then
  echo "Some certificate directories already exist. Move or delete them before."
  echo "Directories:"
  printf "%s\n%s\n%s" "$COMMON_DIR" "$CLIENT_DIR" "$SERVER_DIR"
  exit 1
fi

mkdir -p "$COMMON_DIR" "$CLIENT_DIR" "$SERVER_DIR"

# Common
printf "\e[1;36m%s\e[0;00m\n\n" "Common - Generate CA certificate and its key"
openssl req -new -x509 -days 3650 \
-keyout "$COMMON_DIR"/ca-key \
-out "$COMMON_DIR"/ca-cert  \
-subj "$SUBJ" \
-passin "pass:$SECRET" \
-passout "pass:$SECRET"

# Client
printf "\e[1;36m%s\e[0;00m\n\n" "Client - Generate request certificate and its key"
openssl req -new \
-keyout "$CLIENT_DIR"/cert-key \
-out "$CLIENT_DIR"/cert-file \
-subj "$SUBJ" \
-passin "pass:$SECRET" \
-passout "pass:$SECRET"

printf "\e[1;36m%s\e[0;00m\n\n" "Client - Sign certificate with the CA"
openssl x509 -req -days 365 \
-CA "$COMMON_DIR"/ca-cert \
-CAkey "$COMMON_DIR"/ca-key \
-in "$CLIENT_DIR"/cert-file \
-out "$CLIENT_DIR"/cert-signed \
-CAcreateserial \
-passin "pass:$SECRET"

# Server
printf "\e[1;36m%s\e[0;00m\n\n" "Server - Generate key and certificate for each broker"
keytool -genkey -noprompt -alias localhost -keyalg RSA \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-dname "CN=$broker, OU=society O=society, L=fr, ST=fr, C=fr" \
-storepass "$SECRET" \
-keypass "$SECRET"

printf "\e[1;36m%s\e[0;00m\n\n" "Server - Add the generated CA to the broker and client truststores"
keytool -import -noprompt -alias CARoot \
-keystore "$SERVER_DIR"/kafka.truststore.jks \
-file "$COMMON_DIR"/ca-cert \
-storepass "$SECRET"

printf "\e[1;36m%s\e[0;00m\n\n" "Server - Export the certificate from the keystore"
keytool -certreq -alias localhost \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-file "$SERVER_DIR"/cert-file \
-storepass "$SECRET"

printf "\e[1;36m%s\e[0;00m\n\n" "Server - Sign certificate with the CA"
openssl x509 -req -days 365 \
-CA "$COMMON_DIR"/ca-cert \
-CAkey "$COMMON_DIR"/ca-key \
-in "$SERVER_DIR"/cert-file \
-out "$SERVER_DIR"/cert-signed \
-CAcreateserial \
-passin "pass:$SECRET"

printf "\e[1;36m%s\e[0;00m\n\n" "Server- Import both the CA and the signed certificate into the broker keystore"
keytool -import -noprompt -alias CARoot \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-file "$COMMON_DIR"/ca-cert \
-storepass "$SECRET"

keytool -import -noprompt -alias localhost \
-keystore "$SERVER_DIR"/kafka.keystore.jks \
-file "$SERVER_DIR"/cert-signed \
-storepass "$SECRET"