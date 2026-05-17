package de.neonew.person;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

/**
 * Entry point for the Java example.
 * Reads a CSV file of persons and prints them to stdout.
 *
 * <p>Usage: {@code java -jar target/java-example-*.jar <file.csv>}
 */
public final class Main {

  private Main() {
    // prevent instantiation
  }

  public static void main(String[] args) {
    if (args.length != 1) {
      System.err.println("Usage: java -jar java-example-*.jar <file>");
      System.exit(1);
    }

    Path file = Path.of(args[0]);

    if (!Files.exists(file)) {
      System.err.println("Error: file not found: " + file);
      System.exit(2);
    }

    try (InputStream in = new FileInputStream(file.toFile())) {
      List<Person> people = PersonFileReader.readAll(in);

      if (people.isEmpty()) {
        System.out.println("No persons found in " + file);
        return;
      }

      System.out.println("Found " + people.size() + " person(s):");
      for (Person person : people) {
        System.out.println("  " + person.fullName());
      }
    } catch (IOException e) {
      System.err.println("Error reading file: " + e.getMessage());
      System.exit(3);
    }
  }
}
