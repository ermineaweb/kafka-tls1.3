#!/bin/bash

source env.sh

printf "Env variables:\nbroker: %s\n" "$broker"

COMMON_DIR="cer-common"
CLIENT_DIR="cer-client"
SERVER_DIR="cer-server"

SUBJ="/C=fr/ST=fr/L=fr/O=society/OU=society/CN=$broker/emailAddress=mail@society.com"

if [ -e "$COMMON_DIR" ] || [ -e "$CLIENT_DIR" ] || [ -e "$SERVER_DIR" ]; then
  echo "Some certificate directories already exist. Move or delete them before."
  echo "Directories:"
  printf "%s\n%s\n%s" "$COMMON_DIR" "$CLIENT_DIR" "$SERVER_DIR"
  exit 1
fi

mkdir -p "$COMMON_DIR" "$CLIENT_DIR" "$SERVER_DIR"

# Common
printf "\n\n\e[1;36m%s\e[0;00m\n" "Common - Generate CA certificate and its key\n\n"
openssl req -new -x509 -keyout "$COMMON_DIR"/ca-key -out "$COMMON_DIR"/ca-cert -days 3650 -subj "$SUBJ"

# Client
printf "\n\n\e[1;36m%s\e[0;00m\n" "Client - Generate request certificate and its key\n\n"
openssl req -new -keyout "$CLIENT_DIR"/cert-key -out "$CLIENT_DIR"/cert-file -subj "$SUBJ"

printf "\n\n\e[1;36m%s\e[0;00m\n" "Client - Sign certificate with the CA\n\n"
openssl x509 -req -CA "$COMMON_DIR"/ca-cert -CAkey "$COMMON_DIR"/ca-key -in "$CLIENT_DIR"/cert-file -out "$CLIENT_DIR"/cert-signed -days 365 -CAcreateserial -passin pass:secret

# Server
printf "\n\n\e[1;36m%s\e[0;00m\n" "Server - Generate key and certificate for each broker\n\n"
keytool -keystore "$SERVER_DIR"/kafka.keystore.jks -alias localhost -keyalg RSA -genkey

printf "\n\n\e[1;36m%s\e[0;00m\n" "Server - Add the generated CA to the broker and client truststores\n\n"
keytool -keystore "$SERVER_DIR"/kafka.truststore.jks -alias CARoot -import -file "$COMMON_DIR"/ca-cert

printf "\n\n\e[1;36m%s\e[0;00m\n" "Server - Export the certificate from the keystore\n\n"
keytool -keystore "$SERVER_DIR"/kafka.keystore.jks -alias localhost -certreq -file "$SERVER_DIR"/cert-file

printf "\n\n\e[1;36m%s\e[0;00m\n" "Server - Sign certificate with the CA\n\n"
openssl x509 -req -CA "$COMMON_DIR"/ca-cert -CAkey "$COMMON_DIR"/ca-key -in "$SERVER_DIR"/cert-file -out "$SERVER_DIR"/cert-signed -days 365 -CAcreateserial -passin pass:secret

printf "\n\n\e[1;36m%s\e[0;00m\n" "Server- Import both the CA and the signed certificate into the broker keystore\n\n"
keytool -keystore "$SERVER_DIR"/kafka.keystore.jks -alias CARoot -import -file "$COMMON_DIR"/ca-cert
keytool -keystore "$SERVER_DIR"/kafka.keystore.jks -alias localhost -import -file "$SERVER_DIR"/cert-signed