### Env variables and secrets

Edit the env.sh file with correct values.

```bash
docker secret create kafka-key-2 cer-client/cert-key && \
docker secret create kafka-cert-2 cer-client/cert-signed && \
docker secret create kafka-cacert-2 cer-common/ca-cert
```

### Generate certificates

```bash
./generate-cer.sh
```

### Start server

Start kafka + zookeeper

```bash
./server.sh 1
```

Start kafka only

```bash
./server.sh
```

### Start a client

kafka bitnami tools (producer, consumer, create-topic)

```bash
cd client
./run.sh
```

kafkacat client (producer, consumer)

```bash
cd kcat
./run.sh
```

### Debug

```bash
openssl s_client -connect localhost:9092
```

```bash
docker logs kafka-server | grep ssl.protocol
docker logs kafka-server | grep ssl.cipher.suites
```

```bash
tcpdump -i lo -N -A 'port 9092' -w trace.pcap
tshark -i lo -f 'dst port 9092'
tshark -i lo -f 'src port 9092'
tshark -i lo -f 'port 9092'
```
