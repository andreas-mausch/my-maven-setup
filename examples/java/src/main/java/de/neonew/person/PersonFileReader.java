package de.neonew.person;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * Reads a list of {@link Person} objects from an {@code InputStream}.
 *
 * <p>Each line is expected in {@code LastName, FirstName} format.
 * Empty lines and lines starting with {@code #} are skipped.
 */
public final class PersonFileReader {

  private PersonFileReader() {
    // utility class
  }

  /**
   * Reads all persons from the given input stream.
   */
  public static List<Person> readAll(InputStream input) throws IOException {
    Objects.requireNonNull(input, "input must not be null");

    try (BufferedReader reader = new BufferedReader(
        new InputStreamReader(input, StandardCharsets.UTF_8))) {

      return reader.lines()
          .map(String::trim)
          .filter(line -> !line.isEmpty())
          .filter(line -> !line.startsWith("#"))
          .map(PersonParser::parse)
          .collect(Collectors.toList());
    } catch (UncheckedIOException e) {
      throw e.getCause();
    }
  }
}
