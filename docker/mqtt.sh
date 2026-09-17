#!/bin/sh

# the meshtastic protobuf schema files are GPLv3 licensed and can not be bundled in this MIT licensed
# project (see the "MQTT Collector" section of the README), so fetch them fresh into the same
# src/external/protobufs path mqtt.js looks for by default, if they aren't already present
if [ ! -f "src/external/protobufs/meshtastic/mqtt.proto" ]; then
    echo "Cloning Meshtastic protobufs"
    git clone --depth 1 https://github.com/meshtastic/protobufs src/external/protobufs
fi

# nanopb.proto (used throughout meshtastic's own .proto files for field-size options) imports
# google/protobuf/descriptor.proto, but that's neither part of the meshtastic/protobufs repo nor
# bundled by protobufjs (it only auto-resolves the small wrapper well-known types, not this one),
# so mqtt.js crashes with ENOENT unless it's fetched separately
if [ ! -f "src/external/protobufs/google/protobuf/descriptor.proto" ]; then
    echo "Fetching google/protobuf/descriptor.proto"
    mkdir -p src/external/protobufs/google/protobuf
    wget -q -O src/external/protobufs/google/protobuf/descriptor.proto \
        https://raw.githubusercontent.com/protocolbuffers/protobuf/main/src/google/protobuf/descriptor.proto
fi

echo "Running migrations"
npx prisma migrate dev

echo "Starting mqtt listener"
exec node src/mqtt.js ${MQTT_OPTS}
