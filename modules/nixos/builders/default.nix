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
  };

  config = lib.mkIf cfg.enable {
    # --------------------------------------------------------------------------
    # Secrets (agenix)
    # --------------------------------------------------------------------------
    age.secrets.builder-ssh-key = {
      file = ../../../secrets/shared/builder-ssh-key.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # --------------------------------------------------------------------------
    # Nix Configuration
    # --------------------------------------------------------------------------
    nix = {
      distributedBuilds = true;
      buildMachines = shared.mkBuildMachines builders config.age.secrets.builder-ssh-key.path;
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
        IdentityFile ${config.age.secrets.builder-ssh-key.path}
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
