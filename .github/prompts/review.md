Review this pull request. This is a flake-based NixOS / nix-darwin configuration repo.

## Focus areas

### Nix modules and configuration

1. Module correctness: option declarations, `mkIf` guards, import structure
2. Secrets handling: agenix patterns (`mkSecret` / `mkHomeSecret`), no hardcoded secrets
3. Cross-platform: `isNixOS` / `isDesktop` flags used correctly where needed
4. DRY: no duplicated configuration across hosts or modules

### Shell scripts and CI

1. Command injection: unquoted variables, unsafe interpolation
2. GitHub Actions: incorrect event triggers, overly broad permissions

## Review rules

- Focus on changed lines, not pre-existing code.
- Never flag formatting / whitespace (nixfmt handles it) or style preferences.
- Every finding must describe a specific, reproducible failure scenario.
- Use severity: **Critical** (build / runtime failure, security vulnerability), **Warning** (logic error with specific trigger), **Suggestion** (clearly better alternative).

## Posting

Use `mcp__github_inline_comment__create_inline_comment` for line-specific findings.

Post a top-level summary using `gh pr comment`. The summary MUST start with `<!-- claude-review -->` on its own line (to allow updates on re-runs), followed by:

- **Summary**: 1-3 sentences on what the PR changes.
- **Assessment**: Grouped by severity (omit empty sections), or "No issues found."

Before posting, check for an existing `<!-- claude-review -->` comment:

```bash
gh pr view $PR_NUMBER --repo $REPO --json comments --jq \
  '.comments[] | select(.body | contains("<!-- claude-review -->")) | .url'
```

If found, update it with `gh api <url> -X PATCH -f body='...'`.
If not found, create a new comment with `gh pr comment`.
