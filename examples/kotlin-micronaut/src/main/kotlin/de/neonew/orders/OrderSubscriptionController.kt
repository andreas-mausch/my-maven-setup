package de.neonew.orders

import io.micronaut.http.HttpResponse
import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Post
import io.micronaut.scheduling.TaskExecutors
import io.micronaut.scheduling.annotation.ExecuteOn
import io.micronaut.serde.annotation.Serdeable

@ExecuteOn(TaskExecutors.BLOCKING)
@Controller("/subscriptions")
class OrderSubscriptionController(private val repository: OrderSubscriptionRepository) {
  @Post
  fun create(@Body request: CreateSubscription): HttpResponse<OrderSubscription> =
      HttpResponse.created(repository.save(OrderSubscription(request.orderId)))

  @Get("/{orderId}")
  fun get(orderId: String): HttpResponse<OrderSubscription> =
      repository.findById(orderId).map { HttpResponse.ok(it) }.orElseGet { HttpResponse.notFound() }
}

@Serdeable data class CreateSubscription(val orderId: String)
