{
  config,
  pkgs,
  lib,
  ...
}:

# ==============================================================================
# Cloudreve (Self-hosted Cloud Storage)
# Runs as Podman containers via NixOS oci-containers, matching upstream compose:
# https://github.com/cloudreve/cloudreve/blob/master/docker-compose.yml
# ==============================================================================

let
  cfg = config.hakula.services.cloudreve;

  images = {
    cloudreve = "cloudreve/cloudreve:4.10.1";
    postgres = "postgres:17";
    redis = "redis:7";
  };

  containerNetwork = "cloudreve-net";
  containerExe = lib.getExe pkgs.podman;

  rootlessServiceConfig = {
    User = lib.mkForce "cloudreve";
    Group = lib.mkForce "cloudreve";
    RuntimeDirectory = lib.mkForce "cloudreve";
    RuntimeDirectoryMode = lib.mkForce "0700";
  };

  rootlessEnv = {
    XDG_RUNTIME_DIR = "/run/cloudreve";
    HOME = cfg.dataDir;
  };

  mkRootlessService = after: {
    inherit after;
    requires = [ "cloudreve-network.service" ];
    serviceConfig = rootlessServiceConfig;
    environment = rootlessEnv;
  };
in
{
  options.hakula.services.cloudreve = {
    enable = lib.mkEnableOption "Cloudreve cloud storage service";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/cloudreve";
      description = "Directory for Cloudreve persistent data";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 5212;
      description = "Port for Cloudreve web interface (bound to localhost)";
    };
  };

  config = lib.mkIf cfg.enable {
    # --------------------------------------------------------------------------
    # Container backend
    # --------------------------------------------------------------------------
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    # --------------------------------------------------------------------------
    # Users & Groups
    # --------------------------------------------------------------------------
    users.users.cloudreve = {
      isSystemUser = true;
      group = "cloudreve";
      home = cfg.dataDir;
    };
    users.groups.cloudreve = { };

    # --------------------------------------------------------------------------
    # Secrets (agenix)
    # --------------------------------------------------------------------------
    age.secrets.cloudreve-postgres-password = {
      file = ../../../secrets/shared/cloudreve-postgres-password.age;
      owner = "cloudreve";
      group = "cloudreve";
      mode = "0400";
    };

    # --------------------------------------------------------------------------
    # Filesystem layout
    # --------------------------------------------------------------------------
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 cloudreve cloudreve -"
      "d ${cfg.dataDir}/backend 0755 cloudreve cloudreve -"
      "d ${cfg.dataDir}/postgres 0755 cloudreve cloudreve -"
      "d ${cfg.dataDir}/redis 0755 cloudreve cloudreve -"
    ];

    # --------------------------------------------------------------------------
    # Container network
    # --------------------------------------------------------------------------
    systemd.services.cloudreve-network = {
      description = "Create Podman network for Cloudreve";
      before = [
        "podman-cloudreve-redis.service"
        "podman-cloudreve-postgres.service"
        "podman-cloudreve.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "cloudreve";
        Group = "cloudreve";
        RuntimeDirectory = "cloudreve";
        RuntimeDirectoryMode = "0700";
        ExecStart = "${containerExe} network create ${containerNetwork} || true";
        ExecStop = "${containerExe} network rm ${containerNetwork} || true";
      };
      environment = rootlessEnv;
    };

    # --------------------------------------------------------------------------
    # OCI Containers
    # --------------------------------------------------------------------------
    virtualisation.oci-containers.containers = {
      cloudreve-redis = {
        image = images.redis;
        autoStart = true;
        volumes = [
          "${cfg.dataDir}/redis:/data:U"
        ];
        extraOptions = [
          "--network=${containerNetwork}"
          "--hostname=redis"
        ];
      };

      cloudreve-postgres = {
        image = images.postgres;
        autoStart = true;
        volumes = [
          "${cfg.dataDir}/postgres:/var/lib/postgresql/data:U"
        ];
        environment = {
          POSTGRES_USER = "cloudreve";
          POSTGRES_DB = "cloudreve";
        };
        environmentFiles = [
          config.age.secrets.cloudreve-postgres-password.path
        ];
        extraOptions = [
          "--network=${containerNetwork}"
          "--hostname=postgresql"
        ];
      };

      cloudreve = {
        image = images.cloudreve;
        autoStart = true;
        dependsOn = [
          "cloudreve-redis"
          "cloudreve-postgres"
        ];
        ports = [
          "127.0.0.1:${toString cfg.port}:5212"
          "127.0.0.1:6888:6888"
          "127.0.0.1:6888:6888/udp"
        ];
        volumes = [
          "${cfg.dataDir}/backend:/cloudreve/data:U"
        ];
        environment = {
          "CR_CONF_Database.Type" = "postgres";
          "CR_CONF_Database.Host" = "postgresql";
          "CR_CONF_Database.User" = "cloudreve";
          "CR_CONF_Database.Name" = "cloudreve";
          "CR_CONF_Database.Port" = "5432";
          "CR_CONF_Redis.Server" = "redis:6379";
        };
        environmentFiles = [
          config.age.secrets.cloudreve-postgres-password.path
        ];
        extraOptions = [
          "--network=${containerNetwork}"
        ];
      };
    };

    # --------------------------------------------------------------------------
    # Service ordering
    # --------------------------------------------------------------------------
    systemd.services.podman-cloudreve-postgres = mkRootlessService [
      "cloudreve-network.service"
    ];

    systemd.services.podman-cloudreve-redis = mkRootlessService [
      "cloudreve-network.service"
    ];

    systemd.services.podman-cloudreve = mkRootlessService [
      "cloudreve-network.service"
      "podman-cloudreve-postgres.service"
      "podman-cloudreve-redis.service"
    ];
  };
}
