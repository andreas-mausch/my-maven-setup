package de.neonew.person

import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatIllegalArgumentException
import org.junit.jupiter.api.Test

class PersonParserTest {
  @Test
  fun parseStandardFormat() {
    val person = PersonParser.parse("Doe, John")
    assertThat(person.firstName).isEqualTo("John")
    assertThat(person.lastName).isEqualTo("Doe")
  }

  @Test
  fun parseWithExtraSpaces() {
    assertThat(PersonParser.parse("  Doe   ,   John  ")).isEqualTo(Person("John", "Doe"))
  }

  @Test
  fun parseFullName() {
    assertThat(PersonParser.parse("von Neumann, John")).isEqualTo(Person("John", "von Neumann"))
  }

  @Test
  fun parseRejectsBlankString() {
    assertThatIllegalArgumentException()
        .isThrownBy { PersonParser.parse("   ") }
        .withMessageContaining("blank")
  }

  @Test
  fun parseRejectsMissingComma() {
    assertThatIllegalArgumentException()
        .isThrownBy { PersonParser.parse("John Doe") }
        .withMessageContaining("expected \"Last, First\"")
  }

  @Test
  fun parseRejectsEmptyLastName() {
    assertThatIllegalArgumentException()
        .isThrownBy { PersonParser.parse(", John") }
        .withMessageContaining("must be non-empty")
  }

  @Test
  fun parseRejectsEmptyFirstName() {
    assertThatIllegalArgumentException()
        .isThrownBy { PersonParser.parse("Doe, ") }
        .withMessageContaining("must be non-empty")
  }

  @Test
  fun personFeatures() {
    val person = Person("Jane", "Smith")
    assertThat(person.fullName()).isEqualTo("Jane Smith")
    assertThat(person.lastNameFirst()).isEqualTo("Smith, Jane")
    assertThat(person).isEqualTo(Person("Jane", "Smith"))
  }
}
