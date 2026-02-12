Review this PR. This is a flake-based NixOS / nix-darwin configuration repo.

## Focus areas

1. Module correctness: option declarations, mkIf guards, import structure
2. Secrets handling: agenix patterns (mkSecret / mkHomeSecret), no hardcoded secrets
3. Cross-platform: isNixOS / isDesktop flags used correctly where needed
4. DRY: no duplicated configuration across hosts or modules
5. Error handling: silent failures, missing assertions, unchecked assumptions
6. Security: command injection in shell scripts, unsafe interpolation, exposure of secrets in logs or store paths

## Review principles

- Only report issues you are confident about — no speculative or low-probability concerns.
- Distinguish "this is wrong" (bug, security issue) from "this could be better" (style, structure).
- Do not nitpick formatting — nixfmt handles that.
- Check existing patterns in the codebase before suggesting alternatives.

## Posting the review

You MUST post your review to the PR using GitHub tools — do not just output text.

### Inline review comments

For line-specific issues, use inline review comments on the relevant lines via the GitHub review API.

Each inline comment MUST include a severity prefix:

- **Critical**: Bugs, security vulnerabilities, data loss risks
- **Warning**: Logic errors, missing guards, potential edge-case issues
- **Suggestion**: Style inconsistencies, minor improvements

### Top-level summary comment

The summary comment MUST start with the HTML marker `<!-- claude-review -->` on its own line, followed by this exact structure (omit empty severity sections):

```markdown
<!-- claude-review -->
## Summary

<1-3 sentences: what the PR changes, scope, affected modules / hosts>

## Assessment

### Critical

- <item>

### Warnings

- <item>

### Suggestions

- <item>

## Observations

- <noteworthy items that are not issues>
```

### Updating existing comments

Before posting, search for an existing comment containing `<!-- claude-review -->`:

```bash
gh pr view $PR_NUMBER --repo $REPO --json comments --jq \
  '.comments[] | select(.body | contains("<!-- claude-review -->")) | .url'
```

- If found: update that comment using `gh api <url> -X PATCH -f body='...'`.
- If not found: create a new comment using `gh pr comment`.
