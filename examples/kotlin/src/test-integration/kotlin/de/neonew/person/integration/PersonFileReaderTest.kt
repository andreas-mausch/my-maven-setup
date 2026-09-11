package de.neonew.person.integration

import de.neonew.person.Person
import de.neonew.person.PersonFileReader
import java.nio.file.Files
import java.nio.file.Path
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir

class PersonFileReaderTest {
  @field:TempDir lateinit var tempDir: Path

  @Test
  fun readFromClasspathResource() {
    javaClass.classLoader.getResourceAsStream("test-people.txt").use { input ->
      assertThat(PersonFileReader.readAll(requireNotNull(input)))
          .containsExactly(
              Person("John", "Doe"),
              Person("Jane", "Smith"),
              Person("John", "von Neumann"),
              Person("Bob", "Brown"),
          )
    }
  }

  @Test
  fun readFromFileSkipsComments() {
    val file = tempDir.resolve("comments.txt")
    Files.writeString(
        file,
        "# This is a header comment\nDoe, John\n# Another comment\nBrown, Bob\n",
    )

    Files.newInputStream(file).use { input ->
      assertThat(PersonFileReader.readAll(input))
          .containsExactly(Person("John", "Doe"), Person("Bob", "Brown"))
    }
  }

  @Test
  fun readFromEmptyFile() {
    val file = tempDir.resolve("empty.txt")
    Files.writeString(file, "")

    Files.newInputStream(file).use { input ->
      assertThat(PersonFileReader.readAll(input)).isEmpty()
    }
  }

  @Test
  fun readUtf8() {
    val file = tempDir.resolve("utf8.txt")
    Files.writeString(file, "Müller, François\n")

    Files.newInputStream(file).use { input ->
      assertThat(PersonFileReader.readAll(input)).containsExactly(Person("François", "Müller"))
    }
  }
}
