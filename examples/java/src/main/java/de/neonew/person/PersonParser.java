package de.neonew.person;

import java.util.Objects;

/**
 * Parses {@link Person} instances from {@code LastName, FirstName} strings.
 */
public final class PersonParser {

  private PersonParser() {
    // utility class
  }

  /**
   * Parses a single line into a {@code Person}.
   *
   * @throws IllegalArgumentException if the format is invalid
   */
  public static Person parse(String line) {
    Objects.requireNonNull(line, "line must not be null");

    String trimmed = line.trim();
    if (trimmed.isEmpty()) {
      throw new IllegalArgumentException("line must not be blank");
    }

    int comma = trimmed.indexOf(',');
    if (comma == -1) {
      throw new IllegalArgumentException(
          "Invalid format: \"" + line + "\" — expected \"Last, First\"");
    }

    String lastName = trimmed.substring(0, comma).trim();
    String firstName = trimmed.substring(comma + 1).trim();

    if (lastName.isEmpty() || firstName.isEmpty()) {
      throw new IllegalArgumentException(
          "Both first and last name must be non-empty: \"" + line + "\"");
    }

    return new Person(firstName, lastName);
  }
}
