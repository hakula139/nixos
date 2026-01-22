{
  lib,
  secretsDir ? ".secrets",
}:

# ==============================================================================
# Secrets Helper Library
# ==============================================================================

let
  secretsRoot = ../secrets;
  secretFile = scope: name: "${secretsRoot}/${scope}/${name}.age";
  secretsPath = homeDir: "${homeDir}/${secretsDir}";
in
{
  inherit secretFile secretsPath;

  # ----------------------------------------------------------------------------
  # Secret Declarations
  # ----------------------------------------------------------------------------
  # Standard secret configuration for NixOS modules
  # Returns an age.secrets.<name> configuration for system-level agenix
  mkSecret = scope: name: owner: group: {
    file = secretFile scope name;
    inherit owner group;
    mode = "0400";
  };

  # Standard Home Manager secret configuration
  # Returns an age.secrets.<name> configuration for home-manager agenix
  mkHomeSecret = scope: name: homeDir: {
    file = secretFile scope name;
    path = "${secretsPath homeDir}/${name}";
    mode = "0400";
  };

  # ----------------------------------------------------------------------------
  # Directory Management
  # ----------------------------------------------------------------------------
  # Generate systemd.tmpfiles.rules entry for secrets directory (NixOS)
  mkSecretsDir = user: group: [
    "d ${secretsPath user.home} 0700 ${user.name} ${group} - -"
  ];

  # Generate home.activation script for secrets directory (Home Manager)
  mkHomeSecretsDir = homeDir: ''
    install -d -m 0700 "${secretsPath homeDir}"
  '';
}
