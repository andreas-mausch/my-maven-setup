package de.neonew.orders.integration

import com.rabbitmq.client.Connection
import io.micronaut.context.annotation.Property
import io.micronaut.core.type.Argument
import io.micronaut.http.HttpRequest
import io.micronaut.http.HttpStatus
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.json.JsonMapper
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import io.micronaut.test.support.TestPropertyProvider
import jakarta.inject.Inject
import java.util.concurrent.TimeUnit
import org.assertj.core.api.Assertions.assertThat
import org.awaitility.Awaitility.await
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.testcontainers.containers.MongoDBContainer
import org.testcontainers.containers.RabbitMQContainer
import org.testcontainers.utility.DockerImageName

@MicronautTest(transactional = false)
@Property(name = "spec.name", value = "OrderFlowTest")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class OrderFlowTest : TestPropertyProvider {
  @Inject @field:Client("/") lateinit var client: HttpClient
  @Inject lateinit var rabbitConnection: Connection
  @Inject lateinit var jsonMapper: JsonMapper

  override fun getProperties(): Map<String, String> =
      mapOf("mongodb.uri" to mongo.replicaSetUrl, "rabbitmq.uri" to rabbit.amqpUrl)

  @AfterAll
  fun stopContainers() {
    rabbit.stop()
    mongo.stop()
  }

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

  companion object {
    private val mongo = MongoDBContainer(DockerImageName.parse("mongo:8.0.15"))
    private val rabbit = RabbitMQContainer(DockerImageName.parse("rabbitmq:4.1.4-alpine"))

    init {
      mongo.start()
      rabbit.start()
    }
  }
}

@io.micronaut.serde.annotation.Serdeable
data class OrderSubscriptionResponse(val orderId: String, val status: String)
