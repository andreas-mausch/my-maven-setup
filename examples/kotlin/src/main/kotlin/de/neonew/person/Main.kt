package de.neonew.person

import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.exists

object Main {
  @JvmStatic
  fun main(args: Array<String>) {
    if (args.size != 1) {
      System.err.println("Usage: java -jar kotlin-example-*.jar <file>")
      return
    }

    val file = Path.of(args[0])
    if (!file.exists()) {
      System.err.println("Error: file not found: $file")
      return
    }

    val people = Files.newInputStream(file).use(PersonFileReader::readAll)
    if (people.isEmpty()) {
      println("No persons found in $file")
      return
    }

    println("Found ${people.size} person(s):")
    people.forEach { println("  ${it.fullName()}") }
  }
}
