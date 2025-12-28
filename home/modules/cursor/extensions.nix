{
  pkgs,
  lib,
  inputs,
  homeDirectory,
}:

# ==============================================================================
# Cursor Extensions
# ==============================================================================

let
  marketplace = inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
  vscExtLib = pkgs.vscode-extensions;

  # ============================================================================
  # Extension List
  # ============================================================================
  extensions = with vscExtLib; [
    # --------------------------------------------------------------------------
    # C/C++
    # --------------------------------------------------------------------------
    ms-vscode.cpptools
    llvm-vs-code-extensions.vscode-clangd
    vadimcn.vscode-lldb
    ms-vscode.cmake-tools

    # --------------------------------------------------------------------------
    # Python
    # --------------------------------------------------------------------------
    ms-python.python
    ms-python.vscode-pylance
    ms-python.debugpy
    charliermarsh.ruff

    # --------------------------------------------------------------------------
    # Web Development
    # --------------------------------------------------------------------------
    vue.volar
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    bradlc.vscode-tailwindcss

    # --------------------------------------------------------------------------
    # Go
    # --------------------------------------------------------------------------
    golang.go

    # --------------------------------------------------------------------------
    # Rust
    # --------------------------------------------------------------------------
    rust-lang.rust-analyzer

    # --------------------------------------------------------------------------
    # Haskell
    # --------------------------------------------------------------------------
    haskell.haskell
    marketplace.phoityne.phoityne-vscode

    # --------------------------------------------------------------------------
    # Other Languages
    # --------------------------------------------------------------------------
    jnoortheen.nix-ide
    foxundermoon.shell-format
    redhat.vscode-yaml
    tamasfe.even-better-toml
    mechatroner.rainbow-csv
    samuelcolvin.jinjahtml
    myriad-dreamin.tinymist
    zxh404.vscode-proto3

    # --------------------------------------------------------------------------
    # Remote Development
    # --------------------------------------------------------------------------
    ms-vscode-remote.vscode-remote-extensionpack
    ms-vscode-remote.remote-ssh-edit
    ms-vscode.remote-explorer
    ms-vscode.live-server

    # --------------------------------------------------------------------------
    # Containers & Kubernetes
    # --------------------------------------------------------------------------
    docker.docker
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools

    # --------------------------------------------------------------------------
    # Git & GitHub
    # --------------------------------------------------------------------------
    eamodio.gitlens
    github.vscode-github-actions

    # --------------------------------------------------------------------------
    # Markdown & Documentation
    # --------------------------------------------------------------------------
    shd101wyy.markdown-preview-enhanced
    davidanson.vscode-markdownlint
    yzhang.markdown-all-in-one
    marp-team.marp-vscode
    james-yu.latex-workshop

    # --------------------------------------------------------------------------
    # Utilities & Tools
    # --------------------------------------------------------------------------
    streetsidesoftware.code-spell-checker
    usernamehw.errorlens
    hediet.vscode-drawio
    wakatime.vscode-wakatime

    # --------------------------------------------------------------------------
    # Themes
    # --------------------------------------------------------------------------
    marketplace.t3dotgg.vsc-material-theme-but-i-wont-sue-you
    pkief.material-icon-theme
  ];

  # ============================================================================
  # Extension Helpers
  # ============================================================================
  getExtId = ext: ext.vscodeExtPublisher + "." + ext.vscodeExtName;
  getExtDir = ext: "${getExtId ext}-${ext.version}";
  getExtPath = ext: "${homeDirectory}/.cursor/extensions/${getExtDir ext}";

  # ============================================================================
  # Extensions Metadata (.cursor/extensions/extensions.json)
  # ============================================================================
  mkExtensionMetadata = ext: {
    identifier.id = getExtId ext;
    version = ext.version;
    location = {
      "$mid" = 1;
      scheme = "file";
      path = getExtPath ext;
      fsPath = getExtPath ext;
    };
    relativeLocation = getExtDir ext;
    metadata = {
      isBuiltin = false;
      isApplicationScoped = false;
      isMachineScoped = false;
      isPreReleaseVersion = false;
      preRelease = false;
      hasPreReleaseVersion = false;
      pinned = true;
      source = "gallery";
    };
  };

  extensionsMetadata = map mkExtensionMetadata extensions;
  extensionsJson = (pkgs.formats.json { }).generate "cursor-extensions.json" extensionsMetadata;

  # ============================================================================
  # Extension Installation Scripts (copying to .cursor/extensions)
  # ============================================================================
  mkExtensionCopyScript =
    ext:
    let
      extId = getExtId ext;
      src = "${ext}/share/vscode/extensions/${extId}";
      dest = "$HOME/.cursor/extensions/${getExtDir ext}";
    in
    ''
      # Remove old versions of this extension
      for old in "$base/${extId}"-*; do
        if [ -e "$old" ] && [ "$old" != "${dest}" ]; then
          rm -rf "$old"
        fi
      done

      # Copy extension if not already present
      if [ ! -e "${dest}" ]; then
        cp -R "${src}" "${dest}"
        chmod -R u+rw,go-rwx "${dest}"
      fi
    '';

  extensionCopyScripts = lib.concatMapStringsSep "\n\n" mkExtensionCopyScript extensions;

  declaredExtensions = map getExtDir extensions;
  declaredExtensionsPattern = lib.concatStringsSep "|" declaredExtensions;
in
{
  inherit
    extensions
    extensionsJson
    extensionCopyScripts
    declaredExtensionsPattern
    ;
}
