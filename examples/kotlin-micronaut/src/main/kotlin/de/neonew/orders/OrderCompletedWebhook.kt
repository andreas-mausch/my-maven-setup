package de.neonew.orders

import io.micronaut.http.HttpResponse
import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Post
import io.micronaut.http.client.annotation.Client

@Client("\${webhooks.order-completed.url}")
interface OrderCompletedWebhook {
  @Post("/order-completed")
  fun send(@Body event: OrderCompleted): HttpResponse<Any>
}
