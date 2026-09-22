POST http://localhost:8080/subscriptions
Content-Type: application/json
{
  "orderId": "{{order_id}}"
}
HTTP 201
[Asserts]
jsonpath "$.orderId" == "{{order_id}}"
jsonpath "$.status" == "WAITING"

POST http://localhost:15672/api/exchanges/%2F/orders/publish
Authorization: Basic Z3Vlc3Q6Z3Vlc3Q=
Content-Type: application/json
{
  "properties": {
    "content_type": "application/json"
  },
  "routing_key": "order.completed",
  "payload": "{\"orderId\":\"{{order_id}}\"}",
  "payload_encoding": "string"
}
HTTP 200
[Asserts]
jsonpath "$.routed" == true

GET http://localhost:8080/subscriptions/{{order_id}}
[Options]
retry: 10
retry-interval: 500ms
HTTP 200
[Asserts]
jsonpath "$.orderId" == "{{order_id}}"
jsonpath "$.status" == "COMPLETED"

POST http://localhost:8082/__admin/requests/count
Content-Type: application/json
[Options]
retry: 10
retry-interval: 500ms
{
  "method": "POST",
  "url": "/order-completed",
  "bodyPatterns": [
    {
      "equalToJson": {
        "orderId": "{{order_id}}"
      }
    }
  ]
}
HTTP 200
[Asserts]
jsonpath "$.count" == 1
