{
  pkgs,
  lib,
  ...
}:

# ==============================================================================
# Cross-Platform Notification Support
# ==============================================================================
# - macOS: osascript
# - Linux: notify-send
# - WSL: toasty
# ==============================================================================

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Tiny Windows toast notification CLI for WSL
  # https://github.com/shanselman/toasty
  toasty = pkgs.runCommand "toasty" { } ''
    install -D -m 0755 ${
      pkgs.fetchurl {
        url = "https://github.com/shanselman/toasty/releases/download/v0.5/toasty-x64.exe";
        hash = "sha256-DTlIB4JCcjfGbDFss9+T8rYqvjC4yb/KHu0xZz3NFWQ=";
      }
    } $out/bin/toasty.exe
  '';

  # Cross-platform notification script: notify <title> [body]
  notifyScript = pkgs.writeShellScript "notify" ''
    set -euo pipefail

    title="''${1:-Notification}"
    body="''${2:-}"

    ${lib.optionalString isLinux ''
      # Check if running in WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        "${toasty}/bin/toasty.exe" "$body" -t "$title" --app claude 2>/dev/null || true
      else
        ${pkgs.libnotify}/bin/notify-send "$title" "$body"
      fi
    ''}
    ${lib.optionalString isDarwin ''
      osascript -e "display notification \"$body\" with title \"$title\" sound name \"Glass\""
    ''}
  '';

  # Project-scoped notification: projectNotify <title> <message>
  # Prepends "[project-name #tty]" to the message body.
  mkProjectNotifyScript = pkgs.writeShellScript "project-notify" ''
    set -euo pipefail

    title="''${1:-Notification}"
    message="''${2:-}"
    project="$(basename "$PWD")"
    tty_num="$(ps -o tty= -p $$ 2>/dev/null | grep -oE '[0-9]+$' || echo '?')"

    "${notifyScript}" "$title" "[$project #$tty_num] $message"
  '';
in
{
  inherit notifyScript mkProjectNotifyScript;
}
