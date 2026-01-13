{
  config,
  pkgs,
  lib,
  secretsDir ? "${config.home.homeDirectory}/.secrets",
  isNixOS ? false,
  ...
}:

let
  mcp = import ./mcp.nix {
    inherit
      config
      pkgs
      lib
      secretsDir
      isNixOS
      ;
  };
in
{
  # ============================================================================
  # Claude Code Configuration
  # ============================================================================
  programs.claude-code = {
    enable = true;

    # --------------------------------------------------------------------------
    # MCP configuration
    # --------------------------------------------------------------------------
    mcpServers = {
      Context7 = mcp.servers.context7;
      DeepWiki = mcp.servers.deepwiki;
    };
  };
}
