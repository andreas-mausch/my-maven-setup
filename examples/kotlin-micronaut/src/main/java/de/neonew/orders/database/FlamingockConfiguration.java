package de.neonew.orders.database;

import io.flamingock.api.annotations.EnableFlamingock;
import io.flamingock.api.annotations.Stage;

@EnableFlamingock(stages = @Stage(location = "de.neonew.orders.database.migration"))
public final class FlamingockConfiguration {
  private FlamingockConfiguration() {}
}
