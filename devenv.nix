{ pkgs, config, ... }:

{
  languages.rust.enable = true;

  services.postgres.enable = true;
  services.postgres.initialDatabases = [
    { name = "prediction_pies"; }
  ];

  packages = [ pkgs.sqlx-cli ];

  env.DATABASE_URL = "postgres:///prediction_pies?host=${config.env.PGHOST}";
}
