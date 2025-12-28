{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

# ==============================================================================
# Cursor Configuration
# ==============================================================================

let
  cfg = config.hakula.cursor;
  isDarwin = pkgs.stdenv.isDarwin;

  # Import extension management
  ext = import ./extensions.nix {
    inherit pkgs lib inputs;
    homeDirectory = config.home.homeDirectory;
  };

  # ----------------------------------------------------------------------------
  # Settings Generation
  # ----------------------------------------------------------------------------
  cursorSettingsBase = builtins.fromJSON (builtins.readFile ./settings.json);
  cursorSettingsOverrides = import ./settings.nix { inherit pkgs; };
  cursorSettings = lib.recursiveUpdate cursorSettingsBase cursorSettingsOverrides;
  cursorSettingsJson = (pkgs.formats.json { }).generate "cursor-settings.json" cursorSettings;

  # ----------------------------------------------------------------------------
  # User Files
  # ----------------------------------------------------------------------------
  cursorUserFiles =
    if isDarwin then
      {
        "Library/Application Support/Cursor/User/settings.json".source = cursorSettingsJson;
        "Library/Application Support/Cursor/User/keybindings.json".source = ./keybindings.json;
        "Library/Application Support/Cursor/User/snippets".source = ./snippets;
        ".cursor/extensions/extensions.json".source = ext.extensionsJson;
      }
    else
      {
        "Cursor/User/settings.json".source = cursorSettingsJson;
        "Cursor/User/keybindings.json".source = ./keybindings.json;
        "Cursor/User/snippets".source = ./snippets;
        ".cursor/extensions/extensions.json".source = ext.extensionsJson;
      };

in
{
  # ============================================================================
  # Module Options
  # ============================================================================
  options.hakula.cursor = {
    enable = lib.mkEnableOption "Cursor configuration";

    enableExtensions = lib.mkEnableOption "Cursor extensions";
  };

  # ============================================================================
  # Module Configuration
  # ============================================================================
  config = lib.mkIf cfg.enable {
    # --------------------------------------------------------------------------
    # User Configuration Files
    # --------------------------------------------------------------------------
    home.file = lib.optionalAttrs isDarwin cursorUserFiles;
    xdg.configFile = lib.optionalAttrs (!isDarwin) cursorUserFiles;

    # --------------------------------------------------------------------------
    # Extension Management (Home Manager Activation)
    # --------------------------------------------------------------------------
    home.activation.cursorExtensions = lib.mkIf cfg.enableExtensions (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        base="$HOME/.cursor/extensions"
        mkdir -p "$base"

        ${ext.extensionCopyScripts}

        # Remove undeclared extensions
        for dir in "$base"/*; do
          if [ -d "$dir" ]; then
            name=$(basename "$dir")
            case "$name" in
              ${ext.declaredExtensionsPattern})
                ;;
              anysphere.*)
                ;;
              extensions.json|.obsolete|.DS_Store)
                ;;
              *)
                echo "Removing undeclared extension: $name"
                rm -rf "$dir"
                ;;
            esac
          fi
        done
      ''
    );
  };
}
