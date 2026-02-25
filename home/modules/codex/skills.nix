{
  lib,
  inputs,
  ...
}:

# ==============================================================================
# Codex Skills
# ==============================================================================

let
  skillsSrc = inputs.agent-skills;
  mkSkill = name: "${skillsSrc}/skills/${name}";

  # ----------------------------------------------------------------------------
  # Enabled skills
  # ----------------------------------------------------------------------------
  enabledSkills = {
    # Document format processing (document-skills@anthropic-agent-skills)
    docx = mkSkill "docx";
    pdf = mkSkill "pdf";
    pptx = mkSkill "pptx";
    xlsx = mkSkill "xlsx";

    # General capabilities (example-skills@anthropic-agent-skills)
    algorithmic-art = mkSkill "algorithmic-art";
    brand-guidelines = mkSkill "brand-guidelines";
    canvas-design = mkSkill "canvas-design";
    doc-coauthoring = mkSkill "doc-coauthoring";
    frontend-design = mkSkill "frontend-design";
    internal-comms = mkSkill "internal-comms";
    mcp-builder = mkSkill "mcp-builder";
    skill-creator = mkSkill "skill-creator";
    slack-gif-creator = mkSkill "slack-gif-creator";
    theme-factory = mkSkill "theme-factory";
    web-artifacts-builder = mkSkill "web-artifacts-builder";
    webapp-testing = mkSkill "webapp-testing";
  };
in
{
  inherit enabledSkills;

  # ----------------------------------------------------------------------------
  # Symlink skills into ~/.agents/skills/
  # ----------------------------------------------------------------------------
  homeFiles = lib.mapAttrs' (name: src: {
    name = ".agents/skills/${name}";
    value = {
      source = src;
      recursive = true;
    };
  }) enabledSkills;
}
