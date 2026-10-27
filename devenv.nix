{ pkgs, config, ... }:

let
  instanceId = builtins.substring 0 12 (
    builtins.hashString "sha256" config.devenv.root
  );
  apiHostname = "api.fortune-pies-${instanceId}.localhost";
in {
  process.proxy.enable = true;
  processes.api.proxy.hostname = apiHostname;
  env.API_URL = "http://${apiHostname}";
  languages.rust.enable = true;

  services.postgres.enable = true;
  services.postgres.initialDatabases = [
    { name = "prediction_pies"; }
  ];
  services.postgres.listen_addresses = "127.0.0.1";
  services.postgres.port = 5432;

  # pkgs.git ensures `git` resolves to Nix's binary instead of macOS's
  # /usr/bin/git stub, which breaks under the DEVELOPER_DIR this shell sets
  # for the Rust/Apple-SDK toolchain (xcrun can't find git and errors out).
  packages = [ pkgs.sqlx-cli pkgs.xh pkgs.git ];

  # Explicit user in the URL avoids libpq/whoami falling back to role
  # "anonymous" when the OS username lookup is unavailable (seen under Nix
  # sandboxes).
  env.DATABASE_URL = "postgresql://${builtins.getEnv "USER"}@127.0.0.1:${toString config.env.PGPORT}/prediction_pies";

  processes.api.ports.http.allocate = 3000;
  processes.api.env.PORT = toString config.processes.api.ports.http.value;

  tasks."app:migrate" = {
    exec = "sqlx migrate run";
    after = [ "devenv:processes:postgres@ready" ];
  };

  processes.api = {
    exec = "cargo run";
    after = [ "app:migrate" ];
  };
}
