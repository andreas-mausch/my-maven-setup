package de.neonew.person;

public record Person(String firstName, String lastName) {

  public String fullName() {
    return firstName + " " + lastName;
  }

  public String lastNameFirst() {
    return lastName + ", " + firstName;
  }
}
