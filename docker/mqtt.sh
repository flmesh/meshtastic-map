#!/bin/sh

# the meshtastic protobuf schema files are GPLv3 licensed and can not be bundled in this MIT licensed
# project (see the "MQTT Collector" section of the README), so fetch them fresh into the same
# src/external/protobufs path mqtt.js looks for by default, if they aren't already present.
# Pinned to a specific release tag (https://github.com/meshtastic/protobufs/releases) rather than
# the live default branch, so the ingested schema doesn't silently drift whenever upstream pushes
# new commits - bump this when there's a reason to pick up a newer schema.
MESHTASTIC_PROTOBUFS_VERSION="v2.8.0"

if [ ! -f "src/external/protobufs/meshtastic/mqtt.proto" ]; then
    echo "Fetching Meshtastic protobufs ${MESHTASTIC_PROTOBUFS_VERSION}"
    mkdir -p src/external/protobufs
    wget -q -O /tmp/meshtastic-protobufs.tar.gz \
        "https://github.com/meshtastic/protobufs/archive/refs/tags/${MESHTASTIC_PROTOBUFS_VERSION}.tar.gz"
    tar -xzf /tmp/meshtastic-protobufs.tar.gz -C src/external/protobufs --strip-components=1
    rm /tmp/meshtastic-protobufs.tar.gz
fi

# nanopb.proto (used throughout meshtastic's own .proto files for field-size options) imports
# google/protobuf/descriptor.proto - this isn't part of any meshtastic/protobufs release (it's
# not meshtastic's own file, and doesn't change between meshtastic schema versions) and isn't
# bundled by protobufjs either (it only auto-resolves the small wrapper well-known types, not
# this one), so mqtt.js crashes with ENOENT unless it's fetched separately
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
