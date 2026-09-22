package de.neonew.orders

import com.rabbitmq.client.BuiltinExchangeType
import com.rabbitmq.client.Channel
import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.context.annotation.Value
import io.micronaut.rabbitmq.connect.ChannelInitializer
import jakarta.inject.Singleton

private val logger = KotlinLogging.logger {}

@Singleton
class RabbitTopology(
    @param:Value("\${rabbitmq.exchanges.orders}") private val ordersExchange: String,
    @param:Value("\${rabbitmq.queues.order-completed}") private val orderCompletedQueue: String,
    @param:Value("\${rabbitmq.routing-keys.order-completed}")
    private val orderCompletedRoutingKey: String,
) : ChannelInitializer() {
  override fun initialize(channel: Channel, name: String) {
    channel.exchangeDeclare(ordersExchange, BuiltinExchangeType.TOPIC, true)
    channel.queueDeclare(orderCompletedQueue, true, false, false, emptyMap())
    channel.queueBind(orderCompletedQueue, ordersExchange, orderCompletedRoutingKey)
    logger.info {
      "RabbitMQ topology declared exchange=$ordersExchange queue=$orderCompletedQueue " +
          "routingKey=$orderCompletedRoutingKey"
    }
  }
}
