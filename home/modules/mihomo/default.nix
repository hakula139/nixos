{
  config,
  pkgs,
  lib,
  secrets,
  isNixOS ? false,
  ...
}:

# ==============================================================================
# Mihomo - Clash-compatible proxy service
# ==============================================================================

let
  cfg = config.hakula.mihomo;
  homeDir = config.home.homeDirectory;
  configDir = "${homeDir}/.config/mihomo";
  configFile = "${configDir}/config.yaml";
  subscriptionUrlFile = config.age.secrets.mihomo-subscription-url.path;

  updateScript = pkgs.writeShellScript "mihomo-update" ''
    set -euo pipefail

    SUBSCRIPTION_URL="$(cat ${subscriptionUrlFile})"
    CONFIG_DIR="${configDir}"
    CONFIG_FILE="${configFile}"

    mkdir -p "$CONFIG_DIR"

    echo "Fetching mihomo subscription from: $SUBSCRIPTION_URL"
    ${pkgs.curl}/bin/curl -fsSL "$SUBSCRIPTION_URL" -o "$CONFIG_FILE.tmp"

    if [ ! -s "$CONFIG_FILE.tmp" ]; then
      echo "Error: Downloaded config is empty"
      rm -f "$CONFIG_FILE.tmp"
      exit 1
    fi

    if [ -f "$CONFIG_FILE" ]; then
      echo "Backing up existing config to $CONFIG_FILE.bak"
      cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
    fi

    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "Successfully updated mihomo config"
  '';
in
{
  # ----------------------------------------------------------------------------
  # Module options
  # ----------------------------------------------------------------------------
  options.hakula.mihomo = {
    enable = lib.mkEnableOption "Mihomo proxy service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 7897;
      description = "Mixed port for HTTP / SOCKS proxy";
    };

    updateInterval = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "Systemd calendar interval for subscription updates";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (!isNixOS) {
        # ----------------------------------------------------------------------
        # Secrets
        # ----------------------------------------------------------------------
        age.secrets.mihomo-subscription-url = secrets.mkHomeSecret {
          name = "mihomo-subscription-url";
          inherit homeDir;
        };
      })
      {
        # ----------------------------------------------------------------------
        # Packages
        # ----------------------------------------------------------------------
        home.packages = [ pkgs.mihomo ];

        # ----------------------------------------------------------------------
        # Systemd services
        # ----------------------------------------------------------------------
        systemd.user.services = {
          mihomo-update = {
            Unit = {
              Description = "Update mihomo subscription config";
              After = [ "network-online.target" ];
            };

            Service = {
              Type = "oneshot";
              ExecStart = "${updateScript}";
              RemainAfterExit = false;
            };
          };

          mihomo = {
            Unit = {
              Description = "Mihomo proxy service";
              After = [
                "network-online.target"
                "mihomo-update.service"
              ];
              Wants = [
                "network-online.target"
                "mihomo-update.service"
              ];
            };

            Service = {
              Type = "simple";
              ExecStart = "${pkgs.mihomo}/bin/mihomo -d ${configDir}";
              Restart = "on-failure";
              RestartSec = "5s";
            };

            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        };

        systemd.user.timers.mihomo-update = {
          Unit = {
            Description = "Timer for mihomo subscription updates";
          };

          Timer = {
            OnCalendar = cfg.updateInterval;
            Persistent = true;
            Unit = "mihomo-update.service";
          };

          Install = {
            WantedBy = [ "timers.target" ];
          };
        };

        # ----------------------------------------------------------------------
        # Directory Management
        # ----------------------------------------------------------------------
        home.activation.mihomoSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          install -d -m 0700 "${configDir}"
        '';
      }
    ]
  );
}
