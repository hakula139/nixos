{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:

# ==============================================================================
# NixOS Distributed Builders
# ==============================================================================

let
  shared = import ../../shared.nix { inherit pkgs; };
  cfg = config.hakula.builders;

  # Filter out current host from builders list
  availableBuilders = lib.filterAttrs (name: _: name != hostName) shared.builders;
  builders = builtins.attrValues availableBuilders;
in
{
  # ----------------------------------------------------------------------------
  # Module options
  # ----------------------------------------------------------------------------
  options.hakula.builders = {
    enable = lib.mkEnableOption "distributed builds using remote builders";

    sshKey = lib.mkOption {
      type = lib.types.path;
      default = "/root/.ssh/id_ed25519";
      description = "Path to SSH private key for connecting to builders";
    };
  };

  config = lib.mkIf cfg.enable {
    # --------------------------------------------------------------------------
    # Nix Configuration
    # --------------------------------------------------------------------------
    nix = {
      distributedBuilds = true;
      buildMachines = shared.mkBuildMachines builders cfg.sshKey;
      settings.builders-use-substitutes = true;
    };

    # --------------------------------------------------------------------------
    # SSH Configuration (system-wide)
    # --------------------------------------------------------------------------
    programs.ssh.extraConfig = lib.concatMapStringsSep "\n" (builder: ''
      Host ${builder.name}
        HostName ${builder.ip}
        Port ${toString builder.port}
        User ${builder.sshUser}
        IdentityFile ${cfg.sshKey}
    '') builders;

    programs.ssh.knownHosts = lib.listToAttrs (
      map (builder: {
        name = builder.name;
        value = {
          extraHostNames = [
            builder.ip
            "[${builder.ip}]:${toString builder.port}"
          ];
          publicKey = builder.hostKey;
        };
      }) builders
    );
  };
}
