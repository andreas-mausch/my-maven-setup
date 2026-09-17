package de.neonew.orders.database

import com.mongodb.client.MongoClient
import io.micronaut.configuration.mongo.core.DefaultMongoConfiguration
import io.micronaut.context.annotation.Context
import io.mongock.driver.mongodb.sync.v4.driver.MongoSync4Driver
import io.mongock.runner.standalone.MongockStandalone

@Context
class DatabaseMigration(
    mongoClient: MongoClient,
    mongoConfiguration: DefaultMongoConfiguration,
) {
  init {
    val databaseName = requireNotNull(mongoConfiguration.connectionString.orElseThrow().database) {
      "mongodb.uri must contain a database name"
    }
    val database = mongoClient.getDatabase(databaseName)

    MongockStandalone.builder()
        .setDriver(MongoSync4Driver.withDefaultLock(mongoClient, databaseName))
        .addMigrationScanPackage("de.neonew.orders.database.migration")
        .addDependency(database)
        .buildRunner()
        .execute()
  }
}
