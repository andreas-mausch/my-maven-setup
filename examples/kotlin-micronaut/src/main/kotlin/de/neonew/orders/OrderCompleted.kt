package de.neonew.orders

import io.micronaut.serde.annotation.Serdeable

@Serdeable data class OrderCompleted(val orderId: String)
