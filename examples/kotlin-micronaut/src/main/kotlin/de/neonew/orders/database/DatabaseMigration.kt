package de.neonew.orders.database

import com.mongodb.ConnectionString
import com.mongodb.client.MongoClient
import io.micronaut.context.annotation.Context
import io.micronaut.context.annotation.Value
import io.mongock.driver.mongodb.sync.v4.driver.MongoSync4Driver
import io.mongock.runner.standalone.MongockStandalone

@Context
class DatabaseMigration(mongoClient: MongoClient, @Value("\${mongodb.uri}") mongodbUri: String) {
  init {
    val databaseName = requireNotNull(ConnectionString(mongodbUri).database) {
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
