### Edit env variables

Edit the env.sh file with correct values.

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
