{
  config,
  pkgs,
  lib,
  ...
}:

# ==============================================================================
# Cloudreve (Self-hosted Cloud Storage)
# ==============================================================================

let
  cfg = config.hakula.services.cloudreve;
  serviceName = "cloudreve";
  redisSocket = "/run/redis-${serviceName}/redis.sock";

  configFile = pkgs.writeText "cloudreve-conf.ini" ''
    [System]
    Mode = master
    Listen = :${toString cfg.port}

    [Database]
    Type = postgres
    Host = /run/postgresql
    Port = 5432
    User = ${serviceName}
    Name = ${serviceName}
    UnixSocket = true

    [Redis]
    Network = unix
    Server = ${redisSocket}
    DB = 0
  '';
in
{
  # ----------------------------------------------------------------------------
  # Module options
  # ----------------------------------------------------------------------------
  options.hakula.services.cloudreve = {
    enable = lib.mkEnableOption "Cloudreve cloud storage service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5212;
      description = "Port for Cloudreve web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    # ----------------------------------------------------------------------------
    # Users & Groups
    # ----------------------------------------------------------------------------
    users.users.${serviceName} = {
      isSystemUser = true;
      group = serviceName;
      extraGroups = [ "redis-${serviceName}" ];
    };
    users.groups.${serviceName} = { };

    # ----------------------------------------------------------------------------
    # PostgreSQL (local)
    # ----------------------------------------------------------------------------
    services.postgresql = {
      enable = true;
      enableTCPIP = false;
      ensureDatabases = [ serviceName ];
      ensureUsers = [
        {
          name = serviceName;
          ensureDBOwnership = true;
        }
      ];
      authentication = lib.mkForce ''
        local all postgres peer
        local ${serviceName} ${serviceName} peer
        local all all reject
      '';
    };

    # ----------------------------------------------------------------------------
    # Redis (local)
    # ----------------------------------------------------------------------------
    services.redis.servers.${serviceName} = {
      enable = true;
      port = 0;
      unixSocket = redisSocket;
      unixSocketPerm = 660;
    };

    # ----------------------------------------------------------------------------
    # Cloudreve systemd service
    # ----------------------------------------------------------------------------
    systemd.services.cloudreve = {
      description = "Cloudreve file management and sharing system";
      documentation = [ "https://docs.cloudreve.org" ];

      after = [
        "network.target"
        "postgresql.service"
        "redis-${serviceName}.service"
      ];
      requires = [
        "postgresql.service"
        "redis-${serviceName}.service"
      ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        install -m 0755 ${lib.getExe pkgs.cloudreve} "$STATE_DIRECTORY/cloudreve"
        install -d -m 0750 "$STATE_DIRECTORY/data"
        if [ ! -f "$STATE_DIRECTORY/data/conf.ini" ]; then
          install -m 0600 ${configFile} "$STATE_DIRECTORY/data/conf.ini"
        fi
      '';

      serviceConfig = {
        Type = "simple";
        ExecStart = "%S/${serviceName}/cloudreve";
        Restart = "on-failure";
        RestartSec = "5s";
        User = serviceName;
        Group = serviceName;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        StateDirectory = serviceName;
        StateDirectoryMode = "0750";
        UMask = "0077";
        WorkingDirectory = "%S/${serviceName}";
        ReadWritePaths = [ "%S/${serviceName}" ];
      };
    };
  };
}
