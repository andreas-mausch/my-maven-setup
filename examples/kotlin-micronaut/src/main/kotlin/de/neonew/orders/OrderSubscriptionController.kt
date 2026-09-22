package de.neonew.orders

import com.mongodb.ErrorCategory.DUPLICATE_KEY
import com.mongodb.MongoWriteException
import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.data.exceptions.DataAccessException
import io.micronaut.http.HttpResponse
import io.micronaut.http.HttpStatus
import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Post
import io.micronaut.http.exceptions.HttpStatusException
import io.micronaut.scheduling.TaskExecutors
import io.micronaut.scheduling.annotation.ExecuteOn
import io.micronaut.serde.annotation.Serdeable
import io.micronaut.validation.Validated
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank

private val logger = KotlinLogging.logger {}

@ExecuteOn(TaskExecutors.BLOCKING)
@Controller("/subscriptions")
@Validated
class OrderSubscriptionController(private val repository: OrderSubscriptionRepository) {
  @Post
  fun create(@Body @Valid request: CreateSubscription): HttpResponse<OrderSubscription> {
    val subscription =
        try {
          repository.save(OrderSubscription(request.orderId))
        } catch (exception: DataAccessException) {
          val cause = exception.cause
          if (cause is MongoWriteException && cause.error.category == DUPLICATE_KEY) {
            throw HttpStatusException(
                HttpStatus.CONFLICT,
                "Subscription '${request.orderId}' already exists",
            )
          }
          throw exception
        }
    logger.info {
      "Subscription created orderId=${subscription.orderId} status=${subscription.status}"
    }
    return HttpResponse.created(subscription)
  }

  @Get("/{orderId}")
  fun get(orderId: String): HttpResponse<OrderSubscription> =
      repository.findById(orderId).map { HttpResponse.ok(it) }.orElseGet { HttpResponse.notFound() }
}

@Serdeable data class CreateSubscription(@field:NotBlank val orderId: String)
