package de.neonew.orders

import com.rabbitmq.client.Channel
import io.micronaut.rabbitmq.connect.ChannelInitializer
import jakarta.inject.Singleton

@Singleton
class RabbitTopology : ChannelInitializer() {
  override fun initialize(channel: Channel, name: String) {
    channel.queueDeclare("orders.completed", false, false, false, emptyMap())
  }
}
