{ pkgs, config, ... }:

{
  languages.rust.enable = true;

  services.postgres.enable = true;
  services.postgres.initialDatabases = [
    { name = "prediction_pies"; }
  ];

  packages = [ pkgs.sqlx-cli pkgs.xh ];

  # Explicit user avoids libpq/whoami falling back to role "anonymous" when
  # the OS username lookup is unavailable (seen under Nix sandboxes).
  env.PGUSER = builtins.getEnv "USER";
  env.DATABASE_URL = "postgres:///prediction_pies?host=${config.env.PGHOST}&user=${config.env.PGUSER}";
  env.APP_ADDR = "127.0.0.1:3000";
}
