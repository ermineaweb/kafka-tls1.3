### Env variables and secrets

Edit the env.sh file with correct values.

Optional, setup docker secrets.

```bash
docker secret create kafka-key cer-client/cert-key && \
docker secret create kafka-cert cer-client/cert-signed && \
docker secret create kafka-cacert cer-common/ca-cert
```

### Generate certificates

```bash
./generate-cer.sh
./generate-cer.sh -y
```

### Start server

Start kafka + zookeeper

```bash
./server.sh zoo
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
tshark -i lo -f 'port 9092'
tcpdump -i lo -N -A 'port 9092' -w trace.pcap
tshark -i lo -f 'dst port 9092'
tshark -i lo -f 'src port 9092'
```

```bash
openssl s_client -connect localhost:9092
```

```bash
docker logs kafka-server | grep ssl.protocol
docker logs kafka-server | grep ssl.cipher.suites
```
