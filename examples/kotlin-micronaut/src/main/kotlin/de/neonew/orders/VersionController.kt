package de.neonew.orders

import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.serde.annotation.Serdeable
import java.util.Properties

@Controller("/version")
class VersionController {
  private val version =
      checkNotNull(javaClass.getResourceAsStream("/git.properties")) { "git.properties is missing" }
          .use { input -> Properties().apply { load(input) } }
          .getProperty("git.commit.id.abbrev") ?: error("git.commit.id.abbrev is missing")

  @Get fun version(): VersionResponse = VersionResponse(version)
}

@Serdeable data class VersionResponse(val version: String)
