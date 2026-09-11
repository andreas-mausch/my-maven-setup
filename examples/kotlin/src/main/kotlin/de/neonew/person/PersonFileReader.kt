package de.neonew.person

import java.io.InputStream

object PersonFileReader {
  fun readAll(input: InputStream): List<Person> =
      input.bufferedReader(Charsets.UTF_8).useLines { lines ->
        lines
            .map(String::trim)
            .filter(String::isNotEmpty)
            .filterNot { it.startsWith("#") }
            .map(PersonParser::parse)
            .toList()
      }
}
