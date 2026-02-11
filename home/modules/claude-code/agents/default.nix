{
  lib,
  enabledAgents ? [
    "architect"
    "implementer"
    "researcher"
    "reviewer"
    "tester"
    "codex-worker"
  ],
  codexEnabled ? false,
}:

# ==============================================================================
# Claude Code Custom Agents
# ==============================================================================

let
  allAgents = {
    architect = builtins.readFile ./architect.md;
    implementer = builtins.readFile ./implementer.md;
    researcher = builtins.readFile ./researcher.md;
    reviewer = builtins.readFile ./reviewer.md;
    tester = builtins.readFile ./tester.md;
  }
  // lib.optionalAttrs codexEnabled {
    codex-worker = builtins.readFile ./codex-worker.md;
  };
in
lib.filterAttrs (name: _: builtins.elem name enabledAgents) allAgents
