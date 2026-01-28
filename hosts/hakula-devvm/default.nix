{ ... }:

{
  imports = [
    ../_profiles/docker
  ];

  # ============================================================================
  # Container Configuration
  # ============================================================================
  networking.hostName = "hakula-devvm";

  # ============================================================================
  # Home Manager Overrides
  # ============================================================================
  home-manager.users.hakula = {
    hakula.zsh.fzfTab.enable = false;

    programs.ssh.matchBlocks = {
      "github.com" = {
        hostname = "github-proxy.jqdomain.com";
        forwardAgent = true;
      };
    };

    services.ssh-agent.enable = false;
    services.syncthing.enable = false;
  };

  # ============================================================================
  # System State
  # ============================================================================
  system.stateVersion = "25.11";
}
