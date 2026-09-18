# Kotlin Micronaut Example

This example demonstrates a complete asynchronous application flow:

1. `POST /subscriptions` stores an order subscription in MongoDB through Micronaut Data.
2. A JSON `OrderCompleted` event is published to the `orders.completed` RabbitMQ queue.
3. The typed Micronaut RabbitMQ listener deserializes the event and updates the MongoDB document.
4. The listener sends the event to the configured order-completed webhook.
5. `GET /subscriptions/{orderId}` exposes the resulting state.

`GET /version` returns the abbreviated Git commit embedded in the application at build time.

Mongock runs versioned MongoDB migrations before the application starts serving requests. The example migration in
`de.neonew.orders.database.migration` creates an index for subscription status queries. Mongock records applied change
units in MongoDB and uses a distributed lock, so each migration runs once even when multiple application instances
start.

The unit test covers the domain default. Micronaut Test Resources uses Testcontainers to start real MongoDB and
RabbitMQ containers for the integration test. WireMock verifies the outgoing webhook request. The test invokes the
HTTP endpoint, publishes the event, and waits until both asynchronous effects are observable.

Docker is required for the integration test.

```bash
mvn clean verify
```

## Run locally

Start MongoDB, Mongo Express, and RabbitMQ from the example directory:

```bash
docker compose --file compose.local.yaml up --detach
```

Then start the application with the `local` environment. The local configuration selects the `orders` MongoDB
database, while RabbitMQ uses Micronaut's default connection. Set `ORDER_COMPLETED_WEBHOOK_URL` to the webhook's base
URL.

```bash
MICRONAUT_ENVIRONMENTS=local ORDER_COMPLETED_WEBHOOK_URL=http://localhost:8082 mvn mn:run
```

The application is available at `http://localhost:8080`. Mongo Express is available at `http://localhost:8081`. The
RabbitMQ management UI is available at `http://localhost:15672` with username and password `guest`.

Stop and remove the local containers with:

```bash
docker compose --file compose.local.yaml down --volumes
```

The example uses the repository's shared Shade packaging. Add `-Psize-optimization` to also build the ProGuard JAR with
the Micronaut-specific rules supplied by the parent.
