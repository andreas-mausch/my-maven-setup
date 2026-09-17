package de.neonew.orders.database.migration

import com.mongodb.client.MongoDatabase
import com.mongodb.client.model.IndexOptions
import com.mongodb.client.model.Indexes
import io.mongock.api.annotations.ChangeUnit
import io.mongock.api.annotations.Execution
import io.mongock.api.annotations.RollbackExecution

@ChangeUnit(id = "create-subscription-status-index", order = "001", author = "neonew")
class CreateSubscriptionStatusIndex {
  @Execution
  fun execute(database: MongoDatabase) {
    database
        .getCollection("order_subscription")
        .createIndex(Indexes.ascending("status"), IndexOptions().name(INDEX_NAME))
  }

  @RollbackExecution
  fun rollback(database: MongoDatabase) {
    database.getCollection("order_subscription").dropIndex(INDEX_NAME)
  }

  private companion object {
    const val INDEX_NAME = "idx_order_subscription_status"
  }
}
