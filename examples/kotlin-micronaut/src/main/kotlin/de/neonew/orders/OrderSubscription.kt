package de.neonew.orders

import io.micronaut.data.annotation.Id
import io.micronaut.data.annotation.MappedEntity
import io.micronaut.serde.annotation.Serdeable

@Serdeable
@MappedEntity("order_subscription")
data class OrderSubscription(@field:Id val orderId: String, val status: Status = Status.WAITING) {
  enum class Status {
    WAITING,
    COMPLETED,
  }
}
