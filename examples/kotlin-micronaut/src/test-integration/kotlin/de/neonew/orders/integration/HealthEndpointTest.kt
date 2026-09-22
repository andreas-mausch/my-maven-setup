package de.neonew.orders.integration

import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import jakarta.inject.Inject
import net.javacrumbs.jsonunit.assertj.assertThatJson
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.ValueSource

@MicronautTest
class HealthEndpointTest {
  @Inject @field:Client("/") lateinit var client: HttpClient

  @ParameterizedTest
  @ValueSource(strings = ["/health", "/health/liveness", "/health/readiness"])
  fun `health endpoint reports the application as available`(path: String) {
    val response = client.toBlocking().retrieve(HttpRequest.GET<Any>(path), String::class.java)

    assertThatJson(response) { node("status").isEqualTo("UP") }
  }
}
