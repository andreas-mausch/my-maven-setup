package de.neonew.person;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

import org.junit.jupiter.api.Test;

class PersonParserTest {

  @Test
  void parseStandardFormat() {
    Person person = PersonParser.parse("Doe, John");
    assertThat(person.firstName()).isEqualTo("John");
    assertThat(person.lastName()).isEqualTo("Doe");
  }

  @Test
  void parseWithExtraSpaces() {
    Person person = PersonParser.parse("  Doe   ,   John  ");
    assertThat(person.firstName()).isEqualTo("John");
    assertThat(person.lastName()).isEqualTo("Doe");
  }

  @Test
  void parseFullName() {
    Person person = PersonParser.parse("von Neumann, John");
    assertThat(person.firstName()).isEqualTo("John");
    assertThat(person.lastName()).isEqualTo("von Neumann");
  }

  @Test
  void parseRejectsNull() {
    assertThatNullPointerException()
        .isThrownBy(() -> PersonParser.parse(null));
  }

  @Test
  void parseRejectsBlankString() {
    assertThatIllegalArgumentException()
        .isThrownBy(() -> PersonParser.parse("   "))
        .withMessageContaining("blank");
  }

  @Test
  void parseRejectsMissingComma() {
    assertThatIllegalArgumentException()
        .isThrownBy(() -> PersonParser.parse("John Doe"))
        .withMessageContaining("expected \"Last, First\"");
  }

  @Test
  void parseRejectsEmptyLastName() {
    assertThatIllegalArgumentException()
        .isThrownBy(() -> PersonParser.parse(", John"))
        .withMessageContaining("must be non-empty");
  }

  @Test
  void parseRejectsEmptyFirstName() {
    assertThatIllegalArgumentException()
        .isThrownBy(() -> PersonParser.parse("Doe, "))
        .withMessageContaining("must be non-empty");
  }

  @Test
  void personRecordFeatures() {
    Person person = new Person("Jane", "Smith");
    assertThat(person.fullName()).isEqualTo("Jane Smith");
    assertThat(person.lastNameFirst()).isEqualTo("Smith, Jane");
    assertThat(person)
        .hasFieldOrPropertyWithValue("firstName", "Jane")
        .hasFieldOrPropertyWithValue("lastName", "Smith");
  }

  @Test
  void personEquality() {
    assertThat(new Person("Alice", "Jones"))
        .isEqualTo(new Person("Alice", "Jones"))
        .hasSameHashCodeAs(new Person("Alice", "Jones"));
  }

  @Test
  void personToString() {
    Person person = new Person("Bob", "Brown");
    assertThat(person).hasToString("Person[firstName=Bob, lastName=Brown]");
  }
}
