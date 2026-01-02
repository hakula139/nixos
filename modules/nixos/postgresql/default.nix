{
  config,
  pkgs,
  lib,
  ...
}:

# ==============================================================================
# PostgreSQL (Database Server)
# ==============================================================================

let
  cfg = config.hakula.services.postgresql;
in
{
  # ----------------------------------------------------------------------------
  # Module options
  # ----------------------------------------------------------------------------
  options.hakula.services.postgresql = {
    enable = lib.mkEnableOption "PostgreSQL database server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_17;
      description = "PostgreSQL package / version to use for this host";
    };
  };

  config = lib.mkIf cfg.enable {
    # --------------------------------------------------------------------------
    # PostgreSQL service
    # --------------------------------------------------------------------------
    services.postgresql = {
      enable = true;
      package = cfg.package;
      settings = {
        listen_addresses = lib.mkForce "*";
        password_encryption = lib.mkDefault "scram-sha-256";
      };
    };

    # --------------------------------------------------------------------------
    # Firewall
    # --------------------------------------------------------------------------
    # Allow podman containers to reach PostgreSQL via the podman bridge.
    networking.firewall.interfaces.${config.hakula.podman.network.bridgeInterface}.allowedTCPPorts = [
      5432
    ];
  };
}
