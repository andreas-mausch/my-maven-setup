package de.neonew.person

data class Person(val firstName: String, val lastName: String) {
  fun fullName(): String = "$firstName $lastName"

  fun lastNameFirst(): String = "$lastName, $firstName"
}
