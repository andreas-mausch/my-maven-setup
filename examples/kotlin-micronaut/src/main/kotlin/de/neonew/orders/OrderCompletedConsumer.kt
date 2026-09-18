package de.neonew.orders

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.rabbitmq.annotation.Queue
import io.micronaut.rabbitmq.annotation.RabbitListener

private val logger = KotlinLogging.logger {}

@RabbitListener
class OrderCompletedConsumer(
    private val repository: OrderSubscriptionRepository,
    private val webhook: OrderCompletedWebhook,
) {
  @Queue("\${rabbitmq.queues.order-completed}")
  fun receive(event: OrderCompleted) {
    logger.info { "Order completion event consumed orderId=${event.orderId}" }

    val subscription = repository.findById(event.orderId).orElse(null)
    if (subscription == null) {
      logger.warn { "Subscription not found for order completion event orderId=${event.orderId}" }
      return
    }

    val completed =
        repository.update(subscription.copy(status = OrderSubscription.Status.COMPLETED))
    logger.info { "Subscription completed orderId=${completed.orderId} status=${completed.status}" }

    val response = webhook.send(event)
    logger.info {
      "Order completion webhook called orderId=${event.orderId} status=${response.status.code}"
    }
  }
}
