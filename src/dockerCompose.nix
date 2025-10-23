{
  config,
  pkgs,
  lib,
  ...
}:

{
  branch.nixosModule.nixosModule =
    let
      cfg = config.services.docker-compose;
    in
    {
      options.services.docker-compose = {
        projects = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  composeFile = lib.mkOption {
                    type = lib.types.path;
                    description = "Path to docker-compose.yml";
                  };

                  environmentFiles = lib.mkOption {
                    type = lib.types.listOf lib.types.path;
                    default = [ ];
                    description = "Environment files to load";
                  };
                };
              }
            )
          );
          default = { };
          description = "Docker Compose projects to manage";
        };
      };

      config = lib.mkIf (cfg.projects != { }) {
        systemd.services = lib.mapAttrs' (
          name: project:
          lib.nameValuePair "docker-compose@${name}" {
            description = "Docker Compose project: ${name}";
            after = [
              "docker.service"
              "network-online.target"
            ];
            requires = [
              "docker.service"
              "network-online.target"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              StateDirectory = "docker-compose/${name}";
              WorkingDirectory = "/var/lib/docker-compose/${name}";
              EnvironmentFile = project.environmentFiles;
              ExecStart = pkgs.writeShellScript "docker-compose-${name}-start" ''
                set -euo pipefail
                ${pkgs.docker-compose}/bin/docker-compose \
                  -f ${project.composeFile} \
                  pull --quiet
                ${pkgs.docker-compose}/bin/docker-compose \
                  -f ${project.composeFile} \
                  up -d --remove-orphans
              '';
              ExecStop = pkgs.writeShellScript "docker-compose-${name}-stop" ''
                set -euo pipefail
                ${pkgs.docker-compose}/bin/docker-compose \
                  -f ${project.composeFile} \
                  down
              '';
              ExecReload = pkgs.writeShellScript "docker-compose-${name}-reload" ''
                set -euo pipefail
                ${pkgs.docker-compose}/bin/docker-compose \
                  -f ${project.composeFile} \
                  pull --quiet
                ${pkgs.docker-compose}/bin/docker-compose \
                  -f ${project.composeFile} \
                  up -d --remove-orphans --force-recreate
              '';
              TimeoutStartSec = "10min";
              TimeoutStopSec = "2min";
              Restart = "on-failure";
              RestartSec = "30s";
            };
          }
        ) cfg.projects;
      };
    };
}
