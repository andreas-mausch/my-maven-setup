package de.neonew.orders.integration

import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import jakarta.inject.Inject
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

@MicronautTest
class ApiDocumentationTest {
  @Inject @field:Client("/") lateinit var client: HttpClient

  @Test
  fun `serves generated API documentation`() {
    val documentation =
        client.toBlocking().retrieve(HttpRequest.GET<Any>("/docs/"), String::class.java)
    val specification =
        client
            .toBlocking()
            .retrieve(HttpRequest.GET<Any>("/docs/spec/openapi.yaml"), String::class.java)

    assertThat(documentation).contains("<rapi-doc", "/docs/spec/openapi.yaml")
    assertThat(specification).contains("title: Order Subscriptions API", "/subscriptions:")
  }
}
