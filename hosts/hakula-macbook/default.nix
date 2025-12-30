{ ... }:

{
  imports = [
    ../../modules/darwin
  ];

  # ============================================================================
  # Primary User (required for user-specific system defaults)
  # ============================================================================
  system.primaryUser = "hakula";

  # ============================================================================
  # Secrets (agenix)
  # ============================================================================
  age.identityPaths = [
    "/Users/hakula/.ssh/id_ed25519"
  ];

  age.secrets.brave-api-key = {
    file = ../../secrets/hakula-macbook/brave-api-key.age;
    owner = "hakula";
    mode = "0400";
  };

  age.secrets.context7-api-key = {
    file = ../../secrets/hakula-macbook/context7-api-key.age;
    owner = "hakula";
    mode = "0400";
  };

  # ============================================================================
  # Host-Specific Configuration
  # ============================================================================
  networking.hostName = "Hakula-MacBook";

  # Computer name visible in Finder sidebar, AirDrop, etc.
  networking.computerName = "Hakula-MacBook";

  # Local hostname for Bonjour (hostname.local)
  networking.localHostName = "Hakula-MacBook";

  # ============================================================================
  # User Configuration
  # ============================================================================
  users.users.hakula = {
    name = "hakula";
    home = "/Users/hakula";
  };

  # ============================================================================
  # Host-Specific Packages
  # ============================================================================
  # environment.systemPackages = with pkgs; [
  # ];

  # ============================================================================
  # Host-Specific Homebrew
  # ============================================================================
  homebrew.casks = [
  ];
}
