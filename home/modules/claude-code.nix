{
  config,
  pkgs,
  lib,
  isNixOS ? false,
  ...
}:

let
  proxy = "http://127.0.0.1:7897";
  mcp = import ./mcp.nix {
    inherit
      config
      pkgs
      lib
      isNixOS
      ;
  };
in
lib.mkMerge [
  mcp.secrets
  {
    # ============================================================================
    # Claude Code Configuration
    # ============================================================================
    programs.claude-code = {
      enable = true;

      # --------------------------------------------------------------------------
      # Settings
      # --------------------------------------------------------------------------
      settings = {
        attribution = {
          commit = "";
          pr = "";
        };
        permissions = {
          defaultMode = "acceptEdits";
        };
        env = {
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1;
          HTTPS_PROXY = proxy;
          HTTP_PROXY = proxy;
          NO_PROXY = "localhost,127.0.0.1";
        };
      };

      # --------------------------------------------------------------------------
      # MCP configuration
      # --------------------------------------------------------------------------
      mcpServers = {
        BraveSearch = mcp.servers.braveSearch;
        Context7 = mcp.servers.context7;
        DeepWiki = mcp.servers.deepwiki;
        Filesystem = mcp.servers.filesystem;
        Git = mcp.servers.git;
        Playwright = mcp.servers.playwright;
      };
    };
  }
]
