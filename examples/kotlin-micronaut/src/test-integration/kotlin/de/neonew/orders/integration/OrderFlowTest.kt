package de.neonew.orders.integration

import com.rabbitmq.client.Connection
import io.micronaut.core.type.Argument
import io.micronaut.http.HttpRequest
import io.micronaut.http.HttpStatus
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.json.JsonMapper
import io.micronaut.serde.annotation.Serdeable
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import jakarta.inject.Inject
import java.util.concurrent.TimeUnit
import org.assertj.core.api.Assertions.assertThat
import org.awaitility.Awaitility.await
import org.junit.jupiter.api.Test

@MicronautTest(transactional = false)
class OrderFlowTest {
  @Inject @field:Client("/") lateinit var client: HttpClient
  @Inject lateinit var rabbitConnection: Connection
  @Inject lateinit var jsonMapper: JsonMapper

  @Test
  fun `RabbitMQ event completes subscription stored in MongoDB`() {
    val created =
        client
            .toBlocking()
            .exchange(
                HttpRequest.POST("/subscriptions", mapOf("orderId" to "order-42")),
                Argument.mapOf(String::class.java, Any::class.java),
            )

    assertThat(created.status).isEqualTo(HttpStatus.CREATED)

    rabbitConnection.createChannel().use { channel ->
      channel.basicPublish(
          "",
          "orders.completed",
          null,
          jsonMapper.writeValueAsBytes(mapOf("orderId" to "order-42")),
      )
    }

    await().atMost(10, TimeUnit.SECONDS).untilAsserted {
      val subscription =
          client
              .toBlocking()
              .retrieve(
                  HttpRequest.GET<Any>("/subscriptions/order-42"),
                  OrderSubscriptionResponse::class.java,
              )
      assertThat(subscription.status).isEqualTo("COMPLETED")
    }
  }
}

@Serdeable data class OrderSubscriptionResponse(val orderId: String, val status: String)
