package de.neonew.orders

import io.micronaut.runtime.Micronaut
import io.swagger.v3.oas.annotations.OpenAPIDefinition
import io.swagger.v3.oas.annotations.info.Info

fun main(args: Array<String>) {
  Micronaut.run(Application::class.java, *args)
}

@OpenAPIDefinition(info = Info(title = "Order Subscriptions API")) object Application
