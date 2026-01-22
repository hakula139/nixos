{
  config,
  lib,
  secrets,
  isNixOS ? false,
  ...
}:

# ==============================================================================
# Wakatime Configuration
# ==============================================================================

let
  homeDir = config.home.homeDirectory;
  secretsDir = secrets.secretsPath homeDir;
in
{
  # ----------------------------------------------------------------------------
  # Secrets
  # ----------------------------------------------------------------------------
  config = lib.mkIf (!isNixOS) {
    age.secrets.wakatime-config = {
      file = secrets.secretFile "shared" "wakatime-config";
      path = "${secretsDir}/.wakatime.cfg";
      mode = "0600";
    };
  };
}
