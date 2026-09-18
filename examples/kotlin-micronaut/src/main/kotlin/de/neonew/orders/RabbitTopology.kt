package de.neonew.orders

import com.rabbitmq.client.Channel
import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.context.annotation.Value
import io.micronaut.rabbitmq.connect.ChannelInitializer
import jakarta.inject.Singleton

private val logger = KotlinLogging.logger {}

@Singleton
class RabbitTopology(
    @param:Value("\${rabbitmq.queues.order-completed}") private val orderCompletedQueue: String
) : ChannelInitializer() {
  override fun initialize(channel: Channel, name: String) {
    channel.queueDeclare(orderCompletedQueue, true, false, false, emptyMap())
    logger.info { "RabbitMQ queue declared queue=$orderCompletedQueue" }
  }
}
