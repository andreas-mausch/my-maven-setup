package de.neonew.orders.database.migration

import com.mongodb.client.MongoDatabase
import de.neonew.orders.OrderSubscription
import io.micronaut.data.model.PersistentEntity
import io.micronaut.data.mongodb.operations.MongoCollectionNameProvider
import io.mongock.api.annotations.ChangeUnit
import io.mongock.api.annotations.Execution
import io.mongock.api.annotations.RollbackExecution
import org.bson.Document

@ChangeUnit(id = "create-subscription-status-index", order = "001", author = "neonew")
class CreateSubscriptionStatusIndex(collectionNameProvider: MongoCollectionNameProvider) {
  private val collectionName =
      collectionNameProvider.provide(PersistentEntity.of(OrderSubscription::class.java))

  @Execution
  fun execute(database: MongoDatabase) {
    database.getCollection(collectionName).createIndex(Document("status", 1))
  }

  @RollbackExecution
  fun rollback(database: MongoDatabase) {
    database.getCollection(collectionName).dropIndex(Document("status", 1))
  }
}
