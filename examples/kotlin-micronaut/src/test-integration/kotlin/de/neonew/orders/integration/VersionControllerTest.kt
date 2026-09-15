package de.neonew.orders.integration

import io.micronaut.core.type.Argument
import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import jakarta.inject.Inject
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

@MicronautTest(transactional = false)
class VersionControllerTest {
  @Inject @field:Client("/") lateinit var client: HttpClient

  @Test
  fun `version endpoint exposes git commit`() {
    val response =
        client
            .toBlocking()
            .retrieve(
                HttpRequest.GET<Any>("/version"),
                Argument.mapOf(String::class.java, Any::class.java),
            )

    assertThat(response).containsOnlyKeys("version")
    assertThat(response["version"]).isInstanceOf(String::class.java)
    assertThat(response["version"] as String).matches("[0-9a-f]{7}")
  }
}
