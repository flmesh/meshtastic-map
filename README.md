<h2 align="center">Florida Meshtastic Map</h2>

<p align="center">
<a href="https://discord.gg/K55zeZyHKK"><img src="https://img.shields.io/badge/Discord-Liam%20Cottle's%20Discord-%237289DA?style=flat&logo=discord" alt="discord"/></a>
<a href="https://twitter.com/liamcottle"><img src="https://img.shields.io/badge/Twitter-@liamcottle-%231DA1F2?style=flat&logo=twitter" alt="twitter"/></a>
<br/>
<a href="https://ko-fi.com/liamcottle"><img src="https://img.shields.io/badge/Donate%20a%20Coffee-liamcottle-yellow?style=flat&logo=buy-me-a-coffee" alt="donate on ko-fi"/></a>
<a href="./donate.md"><img src="https://img.shields.io/badge/Donate%20Bitcoin-bc1qy22smke8n4c54evdxmp7lpy9p0e6m9tavtlg2q-%23FF9900?style=flat&logo=bitcoin" alt="donate bitcoin"/></a>
</p>

A map of all Meshtastic nodes heard via MQTT in Florida.

Liam's version of the map is available at https://meshtastic.liamcottle.net

> Check out Liam's new Meshtastic Web Client: [MeshTXT](https://github.com/liamcottle/meshtxt)

<img src="./screenshot.png">

## How does it work?

- An [mqtt client](./src/mqtt.js) is persistently connected to `mqtt.meshtastic.org` and subscribed to the `msh/#` topic.
- All messages received are attempted to be decoded as [ServiceEnvelope](https://buf.build/meshtastic/protobufs/docs/main:meshtastic#meshtastic.ServiceEnvelope) packets.
- If a packet is encrypted, it attempts to decrypt it with the default `AQ==` key.
- If a packet can't be decoded as a `ServiceEnvelope`, it is ignored.
- `NODEINFO_APP` packets add a node to the database.
- `POSITION_APP` packets update the position of a node in the database.
- `NEIGHBORINFO_APP` packets log neighbours heard by a node to the database.
- `TELEMETRY_APP` packets update battery and voltage metrics for a node in the database.
- `TRACEROUTE_APP` packets log all trace routes performed by a node to the database.
- `MAP_REPORT_APP` packets are stored in the database, but are not widely adopted, so are not used yet.
- The database is a MySQL server, and a nodejs express server is running an API to serve data to the map interface.

## Features

- [x] Connects to `mqtt.areyoumeshingwith.us` to collect nodes and metrics.
- [x] Shows nodes on the map if they have reported a valid position.
- [x] Search bar to find nodes by ID, Hex ID, Short Name and Long Name.
- [x] Hover over nodes on the map to see basic information and a preview image.
- [x] Click nodes on the map to show a sidebar with more info such as telemetry graphs and traceroutes.
- [x] Ability to share a direct link to a node. The map will auto navigate to it.
- [x] Device list. To see which hardware models are most popular.
- [x] Mobile optimised layout.
- [x] Settings available to hide nodes from the map if they haven't been updated in a while.
- [x] Real-Time message UI to view `TEXT_MESSAGE_APP` packets as they come in.
- [x] View position history of a node between a selectable time range.
- [x] "Neighbours" map layer. Shows blue connection lines between nodes that heard the other node.
  - This information is taken from the `NEIGHBORINFO_APP`.
  - Some neighbour lines are clearly wrong.
  - Meshtastic firmware older than [v2.3.2](https://github.com/meshtastic/firmware/releases/tag/v2.3.2.63df972) reports MQTT nodes as Neighbours.
  - This was fixed in [meshtastic/firmware/#3457](https://github.com/meshtastic/firmware/pull/3457), but adoption will likely be slow...

## TODO

- use vuejs build process to make managing code easier
- don't use cdn hosted javascript deps so we can run fully offline
  - offline map tiles?
- dedupe packets to prevent spamming database

## Install

Clone the project repo.

```
git clone https://github.com/flmesh/meshtastic-map
cd meshtastic-map
```

Install NodeJS dependencies

```
npm install
```

Create a `.env` environment file.

```
touch .env
```

Add a database [connection string for prisma](https://www.prisma.io/docs/getting-started/setup-prisma/add-to-existing-project/relational-databases/connect-your-database-typescript-postgresql) to `.env` file.

```
DATABASE_URL="mysql://root@localhost:3306/meshtastic-map?connection_limit=100"
```

> Note: Some queries are MySQL specific. Other db providers have not been tested.

Migrate the database.

```
npx prisma migrate dev
```

Run the MQTT listener, to save packets to database.

```
node src/mqtt.js
```

Run the Express Server, to serve the `/api` and Map UI.

```
node src/index.js
# Server running at http://127.0.0.1:8080
```

> Note: You can also use a custom port with `--port 8123`

## Upgrading

Run the following commands from inside the `meshtastic-map` repo.

```
# update repo
git fetch && git pull

# migrate database
npx prisma migrate dev
```

You will now need to restart the `index.js` and `mqtt.js` scripts.

## MQTT Collector

> Please note, due to the Meshtastic protobuf schema files being locked under a GPLv3 license, these are not provided in this MIT licensed project, and must never be committed to this repo's git history.
You will need to obtain these files yourself to be able to use the MQTT Collector.
>
> If you're running via [Docker Compose](#docker-compose), this is handled for you automatically — [docker/mqtt.sh](./docker/mqtt.sh) clones them fresh into `src/external/protobufs` on container start if they aren't already present. If you're running `src/mqtt.js` directly (not via Docker), clone them yourself into the same path;
>
> ```
> git clone https://github.com/meshtastic/protobufs src/external/protobufs
> ```
>
> If you clone and install the Meshtastic protobufs, your use of those files will be subject to the GPLv3 license. This does not change the license of this project being MIT — only the parts you add from the Meshtastic project are covered under GPLv3.

By default, the [MQTT Collector](./src/mqtt.js) connects to the public Meshtastic MQTT server.
Alternatively, you may provide the relevant options shown in the help section below to connect to your own MQTT server along with your own decryption keys.

```
node src/mqtt.js --help
```

```
Meshtastic MQTT Collector

  Collects and processes service envelopes from a Meshtastic MQTT server.

Options

  -h, --help                                    Display this usage guide.
  --mqtt-broker-url string                      MQTT Broker URL (e.g: mqtt://mqtt.meshtastic.org)
  --mqtt-username string                        MQTT Username (e.g: meshdev)
  --mqtt-password string                        MQTT Password (e.g: large4cats)
  --mqtt-topic                                  MQTT Topic to subscribe to (e.g: msh/#)
  --collect-service-envelopes                   This option will save all received service envelopes to the database.
  --collect-text-messages                       This option will save all received text messages to the database.
  --collect-waypoints                           This option will save all received waypoints to the database.
  --collect-neighbour-info                      This option will save all received neighbour infos to the database.
  --collect-map-reports                         This option will save all received map reports to the database.
  --decryption-keys <base64DecryptionKey> ...   Decryption keys encoded in base64 to use when decrypting service envelopes.
  --purge-interval-seconds number               How long to wait between each automatic database purge.
  --purge-nodes-unheard-for-seconds number      Nodes that haven't been heard from in this many seconds will be purged from the database.
```

To connect to your own MQTT server, you could do something like the following;

```
node src/mqtt.js --mqtt-broker-url mqtt://mqtt.example.com --mqtt-username username --mqtt-password password --decryption-keys 1PG7OiApB1nwvP+rz05pAQ==
```

## MQTT Connection Status

> TODO: update this section as this info is now outdated. MQTT status is determined based on a timestamp we update when a packet is gated to MQTT by that node.

The map shows a different coloured icon for nodes based on their connection state to MQTT.

- `Green`: Online (connected to MQTT)
- `Blue`: Offline (disconnected from MQTT)

This works by listening to `/stat/!ID` topics on the MQTT server.

When a node connects to MQTT it publishes `online` to the topic, and when the MQTT server detects the client has disconnected (via an [LWT](https://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament/)) it publishes `offline` to the topic.

The Meshtastic [firmware configures](https://github.com/meshtastic/firmware/blob/279464f96d5139920b017d437501233737daf407/src/mqtt/MQTT.cpp#L330) an [LWT](https://www.hivemq.com/blog/mqtt-essentials-part-9-last-will-and-testament/) (Last Will and Testament), which the MQTT server publishes upon client disconnect.

After a node boots up, there is a ~30 second delay before the `online` state is published.
After a node disconnects from MQTT, there is a ~30 second delay before the `offline` state is published.

This works well when your node connects to MQTT over WiFi, however, when using the `MQTT Client Proxy` feature, your node sends/receives packets to/from your Android/iOS device, and then your device connects to MQTT and proxies the messages.

```
Meshtastic Node <-> Android/iOS <-> MQTT
```

Unfortunately, when using that feature your `online` / `offline` states will not work as expected.

As of the time of writing these docs, the mobile devices do not correctly configure the LWT for the node being proxied, and thus do not publish the `offline` state for the node, so you can't detect if your node disconnected from MQTT.

Your node will stay "stuck" in the `online` state in the MQTT server.

## Docker Compose

A [docker-compose.yml](./docker-compose.yml) is available. You can run the following command to launch everything;

```
docker compose up
```

This will:

- Start a MariaDB database server.
- Run the database migrations.
- Start the MQTT collector.
- Start the Map UI.
- Expose the map on port 8080.

### Configuration

The stack is configured entirely with environment variables (e.g. in a `.env` file next to `docker-compose.yml`, or your platform's environment variable settings):

| Variable   | Description                                                                            | Default                                                 |
|------------|------------------------------------------------------------------------------------------|----------------------------------------------------------|
| `MAP_PORT` | Host port the Map UI is published on (container always listens on `8080`)              | `8080`                                                    |
| `DB_PORT`  | Host port MariaDB is published on (container always listens on `3306`)                 | `3306`                                                    |
| `MQTT_OPTS` | Full CLI flag string passed to [`src/mqtt.js`](./src/mqtt.js) — your broker, credentials, topic, decryption keys, collect flags, etc. See [MQTT Collector](#mqtt-collector) above for the full list of options. | *(empty — connects to the public `mqtt.meshtastic.org`)* |
| `MAP_OPTS`  | Full CLI flag string passed to [`src/index.js`](./src/index.js), e.g. `--port 8123`.   | *(empty)*                                                 |

For example, to remap ports and connect to your own MQTT server:

```
MAP_PORT=9090
DB_PORT=3307
MQTT_OPTS=--mqtt-broker-url mqtt://mqtt.example.com --mqtt-username myuser --mqtt-password mypass --mqtt-topic msh/US/FL/# --collect-neighbour-info --collect-waypoints --collect-map-reports
```

> Note: `--mqtt-topic` values need a trailing `/#` wildcard to match anything below that topic level (e.g. `msh/US/FL/#`, not `msh/US/FL`) — MQTT topic filters are exact-match without one.

### Portainer

To deploy this on a remote [Portainer](https://www.portainer.io/) instance as a Stack:

1. In Portainer, go to **Stacks** → **Add stack**.
2. Give it a name (e.g. `meshtastic-map`).
3. Under **Build method**, choose **Repository**, and point it at this repo (`https://github.com/flmesh/meshtastic-map`), and the branch you want to deploy. This lets Portainer pull `docker-compose.yml` directly and rebuild it on redeploy — you don't need Docker installed anywhere but the target host.
   - Alternatively, choose **Web editor** and paste the contents of `docker-compose.yml` directly if you'd rather not link a repo. If you go this route, remember to re-paste it whenever `docker-compose.yml` changes upstream — Portainer won't pick up repo changes on its own with this method.
4. Under **Environment variables**, add any of the variables from the [Configuration](#configuration) table above that you need (at minimum, `MQTT_OPTS` with your broker details).
5. Click **Deploy the stack**. Portainer will build the image, start MariaDB, run migrations, then start the MQTT collector and Map UI.
6. Once healthy, the map is reachable at `http://<host-address>:<MAP_PORT>` (`8080` by default).

To update later: **Pull and redeploy** if deployed via Repository, or edit-and-redeploy if using the Web editor. Either way, any environment variables you set are preserved across redeploys.

If you're putting this behind a reverse proxy / tunnel (e.g. Pangolin, Cloudflare Tunnel, Nginx Proxy Manager) rather than exposing `MAP_PORT` directly:

- Point the proxy's target at the **container name and internal port** (`meshtastic-map:8080`), not the host's published port — this requires attaching the proxy's container to the same Docker network as this stack (`docker network connect <this-stack's-network> <proxy-container>`), and is generally both simpler and more secure than exposing `MAP_PORT` publicly.
- If your proxy has a "health check" feature, double check it re-reads the target address/port after you edit it — some proxies cache a stale health-check target separately from the routing target when you change it in place, which can make a resource look "unhealthy" even though it's actually routing fine. Deleting and re-adding the target from scratch is a reliable way to force a fresh health check.

## Testing

To execute unit tests, run the following;

```
npm run test
```

## Contributing

If you have a feature request, or find a bug, please [open an issue](https://github.com/liamcottle/meshtastic-map/issues) here on GitHub.

## License

MIT

## Legal

This project is not affiliated with or endorsed by the Meshtastic project.

The Meshtastic logo is the trademark of Meshtastic LLC.

## References

- https://meshtastic.org/docs/software/integrations/mqtt/
- https://buf.build/meshtastic/protobufs/docs/main:meshtastic
- https://github.com/liamcottle/meshtastic-map
