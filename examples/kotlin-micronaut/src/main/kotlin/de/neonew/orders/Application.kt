package de.neonew.orders

import io.micronaut.runtime.Micronaut

fun main(args: Array<String>) {
  Micronaut.run(Application::class.java, *args)
}

object Application
