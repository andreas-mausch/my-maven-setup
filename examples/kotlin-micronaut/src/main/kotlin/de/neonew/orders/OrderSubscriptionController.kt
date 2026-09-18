package de.neonew.orders

import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.http.HttpResponse
import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Post
import io.micronaut.scheduling.TaskExecutors
import io.micronaut.scheduling.annotation.ExecuteOn
import io.micronaut.serde.annotation.Serdeable

private val logger = KotlinLogging.logger {}

@ExecuteOn(TaskExecutors.BLOCKING)
@Controller("/subscriptions")
class OrderSubscriptionController(private val repository: OrderSubscriptionRepository) {
  @Post
  fun create(@Body request: CreateSubscription): HttpResponse<OrderSubscription> {
    val subscription = repository.save(OrderSubscription(request.orderId))
    logger.info { "Subscription created orderId=${subscription.orderId} status=${subscription.status}" }
    return HttpResponse.created(subscription)
  }

  @Get("/{orderId}")
  fun get(orderId: String): HttpResponse<OrderSubscription> =
      repository.findById(orderId).map { HttpResponse.ok(it) }.orElseGet { HttpResponse.notFound() }
}

@Serdeable data class CreateSubscription(val orderId: String)
