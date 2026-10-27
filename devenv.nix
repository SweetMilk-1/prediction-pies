{ pkgs, config, ... }:

let
  instanceId = builtins.substring 0 12 (
    builtins.hashString "sha256" config.devenv.root
  );
  apiHostname = "api.fortune-pies-${instanceId}.localhost";
in {
  packages = with pkgs; [ 
    sqlx-cli xh git prek convco mdformat shfmt shellcheck
  ];

  scripts.fmt.exec = "bash ${config.devenv.root}/scripts/quality.sh fmt";
  scripts.chk.exec = "bash ${config.devenv.root}/scripts/quality.sh chk";

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
