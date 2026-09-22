# Kotlin Micronaut Example

This example demonstrates a complete asynchronous application flow:

1. `POST /subscriptions` stores an order subscription in MongoDB through Micronaut Data.
2. A persistent JSON `OrderCompleted` event is published to the `orders` RabbitMQ topic exchange with the routing key
   `order.completed`.
3. The typed Micronaut RabbitMQ listener deserializes the event and updates the MongoDB document.
4. The listener sends the event to the configured order-completed webhook.
5. `GET /subscriptions/{orderId}` exposes the resulting state.

`GET /version` returns the abbreviated Git commit embedded in the application at build time.

Micronaut Management exposes application health at `/health`, with dedicated `/health/liveness` and
`/health/readiness` endpoints for container orchestration. Health probes are excluded from the HTTP access log.

The OpenAPI specification is generated from the controllers and API models at compile time. Interactive RapiDoc
documentation is available at <http://localhost:8080/docs>, and the generated specification is available at
<http://localhost:8080/docs/spec/openapi.yaml>.

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

## Message persistence

The `orders` exchange and the `order-subscriptions.order-completed` queue are durable. Published events use RabbitMQ
delivery mode `2`, which marks messages as persistent so that the queue can retain them across a broker restart.

## Run locally

### 1. Start the supporting services

From the example directory, start MongoDB, Mongo Express, RabbitMQ, and WireMock:

```bash
docker compose --file compose.local.yaml up --detach
```

### 2. Start the Micronaut application

Start the application with the `local` environment. The local configuration selects the `orders` MongoDB
database and the WireMock server at `http://localhost:8082`. RabbitMQ uses Micronaut's default local connection.

```bash
MICRONAUT_ENVIRONMENTS=local mvn mn:run
```

The local services are available at:

| Service                | URL                      | Username | Password |
|------------------------|--------------------------|----------|----------|
| Micronaut Kotlin       | <http://localhost:8080>  | -        | -        |
| Mongo Express          | <http://localhost:8081>  | `admin`  | `pass`   |
| RabbitMQ management UI | <http://localhost:15672> | `guest`  | `guest`  |
| WireMock               | <http://localhost:8082>  | -        | -        |

WireMock loads the same stub mapping as the integration test.

### 3. Run the example order flow

In another terminal, use [Hurl](https://hurl.dev/) to run and verify the complete asynchronous order flow. Pass a
unique order ID so that the scenario can be run repeatedly without resetting MongoDB:

```bash
hurl --test --variable order_id="order-$(date +%s)" order-flow.hurl
```

The scenario creates a subscription, publishes its completion event through the RabbitMQ management API, waits for
the asynchronous processing, and verifies both the completed subscription and the webhook request received by
WireMock.

The same flow can be executed manually. First create a subscription:

```bash
curl --fail-with-body \
  --header 'Content-Type: application/json' \
  --data '{"orderId":"order-42"}' \
  http://localhost:8080/subscriptions
```

Then publish the corresponding completion event:

```bash
curl --fail-with-body \
  --user guest:guest \
  --header 'Content-Type: application/json' \
  --data '{"properties":{"content_type":"application/json","delivery_mode":2},"routing_key":"order.completed","payload":"{\"orderId\":\"order-42\"}","payload_encoding":"string"}' \
  http://localhost:15672/api/exchanges/%2F/orders/publish
```

The publish response contains `"routed":true`. The application consumes the event asynchronously. Verify the updated
subscription and inspect the request received by WireMock:

```bash
curl --fail-with-body http://localhost:8080/subscriptions/order-42
curl --fail-with-body http://localhost:8082/__admin/requests
```

The subscription status is `COMPLETED`, and WireMock lists a `POST /order-completed` request containing the order ID.
WireMock's stub is defined in `src/test-integration/resources/mappings/order-completed.json`.

To start with empty MongoDB data and an empty WireMock request journal, stop the application and recreate the local
containers:

```bash
docker compose --file compose.local.yaml down --volumes
```
