package de.neonew.orders.integration

import com.github.tomakehurst.wiremock.client.WireMock.configureFor
import com.github.tomakehurst.wiremock.client.WireMock.equalToJson
import com.github.tomakehurst.wiremock.client.WireMock.exactly
import com.github.tomakehurst.wiremock.client.WireMock.postRequestedFor
import com.github.tomakehurst.wiremock.client.WireMock.urlEqualTo
import com.github.tomakehurst.wiremock.client.WireMock.verify
import com.rabbitmq.client.Connection
import com.rabbitmq.client.MessageProperties
import io.micronaut.context.annotation.Value
import io.micronaut.core.type.Argument
import io.micronaut.http.HttpRequest
import io.micronaut.http.HttpStatus
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.http.client.exceptions.HttpClientResponseException
import io.micronaut.json.JsonMapper
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import jakarta.inject.Inject
import java.util.concurrent.TimeUnit
import net.javacrumbs.jsonunit.assertj.assertThatJson
import org.assertj.core.api.Assertions.assertThat
import org.awaitility.Awaitility.await
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows

@MicronautTest(transactional = false)
class OrderFlowTest {
  @Inject @field:Client("/") lateinit var client: HttpClient
  @Inject lateinit var rabbitConnection: Connection
  @Inject lateinit var jsonMapper: JsonMapper
  @Value("\${rabbitmq.exchanges.orders}") lateinit var ordersExchange: String
  @Value("\${rabbitmq.routing-keys.order-completed}") lateinit var orderCompletedRoutingKey: String
  @Value("\${wiremock.host}") lateinit var wireMockHost: String
  @Value("\${wiremock.port}") var wireMockPort: Int = 0

  @Test
  fun `RabbitMQ event completes subscription and invokes webhook`() {
    configureFor(wireMockHost, wireMockPort)

    val created =
        client
            .toBlocking()
            .exchange(
                HttpRequest.POST("/subscriptions", mapOf("orderId" to "order-42")),
                Argument.mapOf(String::class.java, Any::class.java),
            )

    assertThat(created.status).isEqualTo(HttpStatus.CREATED)

    val waiting =
        client
            .toBlocking()
            .retrieve(
                HttpRequest.GET<Any>("/subscriptions/order-42"),
                String::class.java,
            )
    assertThatJson(waiting) {
      node("orderId").isEqualTo("order-42")
      node("status").isEqualTo("WAITING")
    }

    rabbitConnection.createChannel().use { channel ->
      channel.basicPublish(
          ordersExchange,
          orderCompletedRoutingKey,
          MessageProperties.PERSISTENT_BASIC,
          jsonMapper.writeValueAsBytes(mapOf("orderId" to "order-42")),
      )
    }

    await().atMost(10, TimeUnit.SECONDS).untilAsserted {
      val subscription =
          client
              .toBlocking()
              .retrieve(
                  HttpRequest.GET<Any>("/subscriptions/order-42"),
                  String::class.java,
              )
      assertThatJson(subscription) {
        node("orderId").isEqualTo("order-42")
        node("status").isEqualTo("COMPLETED")
      }
      verify(
          exactly(1),
          postRequestedFor(urlEqualTo("/order-completed"))
              .withRequestBody(equalToJson("""{"orderId":"order-42"}""")),
      )
    }
  }

  @Test
  fun `Creating an existing subscription returns conflict`() {
    val request = HttpRequest.POST("/subscriptions", mapOf("orderId" to "duplicate-order"))

    client.toBlocking().exchange(request, Argument.mapOf(String::class.java, Any::class.java))

    val exception =
        assertThrows<HttpClientResponseException> {
          client.toBlocking().exchange(request, Argument.OBJECT_ARGUMENT)
        }
    assertThat(exception.status).isEqualTo(HttpStatus.CONFLICT)
  }

  @Test
  fun `Creating a subscription with a blank order ID returns bad request`() {
    val request = HttpRequest.POST("/subscriptions", mapOf("orderId" to " "))

    val exception =
        assertThrows<HttpClientResponseException> {
          client.toBlocking().exchange(request, Argument.OBJECT_ARGUMENT)
        }
    assertThat(exception.status).isEqualTo(HttpStatus.BAD_REQUEST)
  }
}
