package de.neonew.orders.database

import com.mongodb.client.MongoClient
import io.github.oshai.kotlinlogging.KotlinLogging
import io.micronaut.configuration.mongo.core.DefaultMongoConfiguration
import io.micronaut.context.annotation.Context
import io.micronaut.data.mongodb.operations.MongoCollectionNameProvider
import io.flamingock.community.Flamingock
import io.flamingock.store.mongodb.sync.MongoDBSyncAuditStore
import io.flamingock.targetsystem.mongodb.sync.MongoDBSyncTargetSystem

private val logger = KotlinLogging.logger {}

@Context
class DatabaseMigration(
    client: MongoClient,
    configuration: DefaultMongoConfiguration,
    collectionNameProvider: MongoCollectionNameProvider,
) {
  init {
    val databaseName =
        requireNotNull(configuration.connectionString.orElseThrow().database) {
          "mongodb.uri must contain a database name"
        }
    val mongoTarget =
        MongoDBSyncTargetSystem(MONGO_TARGET_SYSTEM, client, databaseName)
            .addDependency(collectionNameProvider)

    logger.info { "Running database migrations for database $databaseName" }
    Flamingock.builder()
        .setAuditStore(MongoDBSyncAuditStore.from(mongoTarget))
        .addTargetSystems(mongoTarget)
        .build()
        .run()
    logger.info { "Database migrations completed for database $databaseName" }
  }
}

const val MONGO_TARGET_SYSTEM = "mongo"
