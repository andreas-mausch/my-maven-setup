package de.neonew.orders.integration

import io.micronaut.http.HttpRequest
import io.micronaut.http.client.HttpClient
import io.micronaut.http.client.annotation.Client
import io.micronaut.test.extensions.junit5.annotation.MicronautTest
import jakarta.inject.Inject
import net.javacrumbs.jsonunit.assertj.assertThatJson
import org.junit.jupiter.api.Test

@MicronautTest
class VersionControllerTest {
  @Inject @field:Client("/") lateinit var client: HttpClient

  @Test
  fun `version endpoint exposes git commit`() {
    val response =
        client.toBlocking().retrieve(HttpRequest.GET<Any>("/version"), String::class.java)

    assertThatJson(response) { node("version").isString.matches("[0-9a-f]{7}") }
  }
}
