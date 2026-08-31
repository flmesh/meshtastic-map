#!/bin/sh

# the meshtastic protobuf schema files are GPLv3 licensed and can not be bundled in this MIT licensed
# project (see the "MQTT Collector" section of the README), so fetch them fresh into the same
# src/external/protobufs path mqtt.js looks for by default, if they aren't already present
if [ ! -f "src/external/protobufs/meshtastic/mqtt.proto" ]; then
    echo "Cloning Meshtastic protobufs"
    git clone --depth 1 https://github.com/meshtastic/protobufs src/external/protobufs
fi

echo "Running migrations"
npx prisma migrate dev

echo "Starting mqtt listener"
exec node src/mqtt.js ${MQTT_OPTS}
