package de.neonew.person

object PersonParser {
  fun parse(line: String): Person {
    val trimmed = line.trim()
    require(trimmed.isNotEmpty()) { "line must not be blank" }

    val comma = trimmed.indexOf(',')
    require(comma >= 0) { "Invalid format: \"$line\" - expected \"Last, First\"" }

    val lastName = trimmed.substring(0, comma).trim()
    val firstName = trimmed.substring(comma + 1).trim()
    require(lastName.isNotEmpty() && firstName.isNotEmpty()) {
      "Both first and last name must be non-empty: \"$line\""
    }

    return Person(firstName, lastName)
  }
}
