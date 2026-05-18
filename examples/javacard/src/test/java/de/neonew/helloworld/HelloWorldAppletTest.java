package de.neonew.helloworld;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

public class HelloWorldAppletTest {

  @Test
  public void testHelloWorld() {
    assertThat(HelloWorldApplet.class).isNotNull();
  }
}
