package de.neonew.orders

import io.micronaut.rabbitmq.annotation.Queue
import io.micronaut.rabbitmq.annotation.RabbitListener

@RabbitListener
class OrderCompletedConsumer(private val repository: OrderSubscriptionRepository) {
  @Queue("\${rabbitmq.queues.order-completed}")
  fun receive(event: OrderCompleted) {
    repository.findById(event.orderId).ifPresent {
      repository.update(it.copy(status = OrderSubscription.Status.COMPLETED))
    }
  }
}
