package de.neonew.orders.database

import com.mongodb.client.MongoClient
import io.micronaut.configuration.mongo.core.DefaultMongoConfiguration
import io.micronaut.context.annotation.Context
import io.micronaut.data.mongodb.operations.MongoCollectionNameProvider
import io.mongock.driver.mongodb.sync.v4.driver.MongoSync4Driver
import io.mongock.runner.standalone.MongockStandalone

@Context
class DatabaseMigration(
    client: MongoClient,
    configuration: DefaultMongoConfiguration,
    collectionNameProvider: MongoCollectionNameProvider,
) {
  init {
    val databaseName = requireNotNull(configuration.connectionString.orElseThrow().database) {
      "mongodb.uri must contain a database name"
    }
    val database = client.getDatabase(databaseName)

    MongockStandalone.builder()
        .setDriver(MongoSync4Driver.withDefaultLock(client, databaseName))
        .addMigrationScanPackage("de.neonew.orders.database.migration")
        .addDependency(database)
        .addDependency(collectionNameProvider)
        .buildRunner()
        .execute()
  }
}
