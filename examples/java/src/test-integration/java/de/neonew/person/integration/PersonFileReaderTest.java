package de.neonew.person.integration;

import static org.assertj.core.api.Assertions.assertThat;

import de.neonew.person.Person;
import de.neonew.person.PersonFileReader;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class PersonFileReaderTest {

  @TempDir
  Path tempDir;

  @Test
  void readFromClasspathResource() throws IOException {
    try (InputStream in = getClass().getClassLoader()
        .getResourceAsStream("test-people.txt")) {
      List<Person> people = PersonFileReader.readAll(in);
      assertThat(people).hasSize(4);
      assertThat(people.get(0)).isEqualTo(new Person("John", "Doe"));
      assertThat(people.get(1)).isEqualTo(new Person("Jane", "Smith"));
      assertThat(people.get(2)).isEqualTo(new Person("John", "von Neumann"));
      assertThat(people.get(3)).isEqualTo(new Person("Bob", "Brown"));
    }
  }

  @Test
  void readFromFileSkipsComments() throws IOException {
    Path file = tempDir.resolve("comments.txt");
    Files.writeString(file, """
        # This is a header comment
        Doe, John
        # Another comment
        Brown, Bob

        """);

    try (InputStream in = Files.newInputStream(file)) {
      List<Person> people = PersonFileReader.readAll(in);
      assertThat(people).hasSize(2);
      assertThat(people.get(0).fullName()).isEqualTo("John Doe");
      assertThat(people.get(1).fullName()).isEqualTo("Bob Brown");
    }
  }

  @Test
  void readFromFileEmpty() throws IOException {
    Path file = tempDir.resolve("empty.txt");
    Files.writeString(file, "");

    try (InputStream in = Files.newInputStream(file)) {
      List<Person> people = PersonFileReader.readAll(in);
      assertThat(people).isEmpty();
    }
  }

  @Test
  void readFromFileOnlyComments() throws IOException {
    Path file = tempDir.resolve("comments-only.txt");
    Files.writeString(file, "# just a comment\n  \n# another\n");

    try (InputStream in = Files.newInputStream(file)) {
      List<Person> people = PersonFileReader.readAll(in);
      assertThat(people).isEmpty();
    }
  }

  @Test
  void readInvalidLine() {
    org.junit.jupiter.api.Assertions.assertThrows(
        IllegalArgumentException.class,
        () -> {
          Path file = tempDir.resolve("bad.txt");
          Files.writeString(file, "Doe, John\nNotValid\n");
          try (InputStream in = Files.newInputStream(file)) {
            PersonFileReader.readAll(in);
          }
        });
  }

  @Test
  void utf8Encoding() throws IOException {
    // Use a name with non-ASCII characters
    Path file = tempDir.resolve("utf8.txt");
    Files.writeString(file, "Müller, François\n");

    try (InputStream in = Files.newInputStream(file)) {
      List<Person> people = PersonFileReader.readAll(in);
      assertThat(people).hasSize(1);
      assertThat(people.get(0).firstName()).isEqualTo("François");
      assertThat(people.get(0).lastName()).isEqualTo("Müller");
    }
  }
}
