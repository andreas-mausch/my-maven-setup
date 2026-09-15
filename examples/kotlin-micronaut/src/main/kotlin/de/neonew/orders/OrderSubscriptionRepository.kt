package de.neonew.orders

import io.micronaut.data.mongodb.annotation.MongoRepository
import io.micronaut.data.repository.CrudRepository

@MongoRepository interface OrderSubscriptionRepository : CrudRepository<OrderSubscription, String>
