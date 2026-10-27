{ pkgs, config, ... }:

{
  languages.rust.enable = true;

  services.postgres.enable = true;
  services.postgres.initialDatabases = [
    { name = "prediction_pies"; }
  ];

  # pkgs.git ensures `git` resolves to Nix's binary instead of macOS's
  # /usr/bin/git stub, which breaks under the DEVELOPER_DIR this shell sets
  # for the Rust/Apple-SDK toolchain (xcrun can't find git and errors out).
  packages = [ pkgs.sqlx-cli pkgs.xh pkgs.git ];

  # Explicit user avoids libpq/whoami falling back to role "anonymous" when
  # the OS username lookup is unavailable (seen under Nix sandboxes).
  env.PGUSER = builtins.getEnv "USER";
  env.DATABASE_URL = "postgres:///prediction_pies?host=${config.env.PGHOST}&user=${config.env.PGUSER}";
  env.APP_ADDR = "127.0.0.1:3000";
}
