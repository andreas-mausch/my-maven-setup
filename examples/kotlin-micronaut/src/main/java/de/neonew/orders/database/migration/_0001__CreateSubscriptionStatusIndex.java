package de.neonew.orders.database.migration;

import com.mongodb.client.MongoDatabase;
import de.neonew.orders.OrderSubscription;
import de.neonew.orders.database.DatabaseMigrationKt;
import io.flamingock.api.annotations.Apply;
import io.flamingock.api.annotations.Change;
import io.flamingock.api.annotations.Rollback;
import io.flamingock.api.annotations.TargetSystem;
import io.micronaut.data.model.PersistentEntity;
import io.micronaut.data.mongodb.operations.MongoCollectionNameProvider;
import org.bson.Document;

@TargetSystem(id = DatabaseMigrationKt.MONGO_TARGET_SYSTEM)
@Change(id = "create-subscription-status-index", author = "neonew", transactional = false)
public final class _0001__CreateSubscriptionStatusIndex {
  @Apply
  public void apply(
      MongoDatabase database, MongoCollectionNameProvider collectionNameProvider) {
    database.getCollection(collectionName(collectionNameProvider)).createIndex(new Document("status", 1));
  }

  @Rollback
  public void rollback(
      MongoDatabase database, MongoCollectionNameProvider collectionNameProvider) {
    database.getCollection(collectionName(collectionNameProvider)).dropIndex(new Document("status", 1));
  }

  private String collectionName(MongoCollectionNameProvider collectionNameProvider) {
    return collectionNameProvider.provide(PersistentEntity.of(OrderSubscription.class));
  }
}
