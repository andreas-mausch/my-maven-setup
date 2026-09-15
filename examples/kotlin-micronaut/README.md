# Kotlin Micronaut Example

This example demonstrates a complete asynchronous application flow:

1. `POST /subscriptions` stores an order subscription in MongoDB through Micronaut Data.
2. A JSON `OrderCompleted` event is published to the `orders.completed` RabbitMQ queue.
3. The typed Micronaut RabbitMQ listener deserializes the event and updates the MongoDB document.
4. `GET /subscriptions/{orderId}` exposes the resulting state.

The unit test covers the domain default. The integration test starts real MongoDB and RabbitMQ containers, invokes the
HTTP endpoint, publishes the event, and waits until the asynchronous state change is visible through HTTP.

Docker is required for the integration test.

```bash
mvn clean verify
```

The example uses the repository's shared Shade packaging. Add `-Psize-optimization` to also build the ProGuard JAR with
the Micronaut-specific rules supplied by the parent.
