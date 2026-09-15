package de.neonew.orders

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class OrderSubscriptionTest {
  @Test
  fun `new subscriptions wait for completion`() {
    val subscription = OrderSubscription("order-1")

    assertThat(subscription.status).isEqualTo(OrderSubscription.Status.WAITING)
  }
}
