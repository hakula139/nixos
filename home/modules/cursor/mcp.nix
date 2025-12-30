{
  config,
  pkgs,
  ...
}:

# ==============================================================================
# Cursor MCP (Model Context Protocol) Configuration
# ==============================================================================

let
  isDarwin = pkgs.stdenv.isDarwin;
  homeDir = config.home.homeDirectory;

  # ----------------------------------------------------------------------------
  # Brave Search MCP
  # ----------------------------------------------------------------------------
  # You need to manually decrypt secrets/shared/brave-api-key.age to this path.
  braveApiKeyFile = "${homeDir}/.secrets/brave-api-key";

  braveSearch = pkgs.writeShellScriptBin "brave-search-mcp" ''
    if [ -f "${braveApiKeyFile}" ]; then
      export BRAVE_API_KEY="$(cat ${braveApiKeyFile})"
    fi
    exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-brave-search "$@"
  '';

  # ----------------------------------------------------------------------------
  # Context7 MCP
  # ----------------------------------------------------------------------------
  # You need to manually decrypt secrets/shared/context7-api-key.age to this path.
  context7ApiKeyFile = "${homeDir}/.secrets/context7-api-key";
  context7ApiKey = builtins.readFile context7ApiKeyFile;

  # ----------------------------------------------------------------------------
  # GitKraken MCP
  # ----------------------------------------------------------------------------
  gitKrakenPath =
    if isDarwin then
      "${homeDir}/Library/Application Support/Cursor/User/globalStorage/eamodio.gitlens/gk"
    else
      "${homeDir}/.config/Cursor/User/globalStorage/eamodio.gitlens/gk";

  # ----------------------------------------------------------------------------
  # MCP Configuration
  # ----------------------------------------------------------------------------
  mcpConfig = {
    mcpServers = {
      BraveSearch = {
        name = "BraveSearch";
        command = "${braveSearch}/bin/brave-search-mcp";
        type = "stdio";
      };
      Context7 = {
        name = "Context7";
        url = "https://mcp.context7.com/mcp";
        headers = {
          "CONTEXT7_API_KEY" = context7ApiKey;
        };
      };
      DeepWiki = {
        name = "DeepWiki";
        url = "https://mcp.deepwiki.com/sse";
      };
      GitKraken = {
        name = "GitKraken";
        command = gitKrakenPath;
        type = "stdio";
        args = [
          "mcp"
          "--host=cursor"
          "--source=gitlens"
          "--scheme=cursor"
        ];
      };
    };
  };
in
{
  # ============================================================================
  # MCP Configuration Generation
  # ============================================================================
  mcpJson = (pkgs.formats.json { }).generate "cursor-mcp.json" mcpConfig;
}
