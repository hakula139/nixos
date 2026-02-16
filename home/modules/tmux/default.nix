{ pkgs, ... }:

# ==============================================================================
# tmux (Terminal Multiplexer)
# ==============================================================================

{
  programs.tmux = {
    enable = true;

    # --------------------------------------------------------------------------
    # Core settings
    # --------------------------------------------------------------------------
    baseIndex = 1;
    clock24 = true;
    disableConfirmationPrompt = true;
    escapeTime = 1;
    focusEvents = true;
    historyLimit = 50000;
    keyMode = "emacs";
    mouse = true;
    prefix = "C-a";
    sensibleOnTop = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";

    # --------------------------------------------------------------------------
    # Plugins
    # --------------------------------------------------------------------------
    plugins = with pkgs.tmuxPlugins; [
      # Color scheme
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
        '';
      }

      # System clipboard integration
      yank

      # Session persistence
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }

      # Auto-save sessions
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    # --------------------------------------------------------------------------
    # Extra configuration
    # --------------------------------------------------------------------------
    extraConfig = ''
      # True color support for modern terminals
      set -sa terminal-features ",xterm*:RGB"

      # Send Ctrl-a to underlying app with double-press
      bind C-a send-prefix

      # Intuitive split keys
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # New windows inherit current path
      bind c new-window -c "#{pane_current_path}"

      # Mouse wheel: enter copy mode without half-page jump, scroll 1 line at a time
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e'"
      bind -T copy-mode WheelUpPane select-pane \; send-keys -X -N 1 scroll-up
      bind -T copy-mode WheelDownPane select-pane \; send-keys -X -N 1 scroll-down

      # Refresh VS Code / Cursor env vars on reattach (prevents stale auth tokens)
      set -ga update-environment " VSCODE_GIT_ASKPASS_NODE"
      set -ga update-environment " VSCODE_GIT_ASKPASS_EXTRA_ARGS"
      set -ga update-environment " VSCODE_GIT_ASKPASS_MAIN"
      set -ga update-environment " VSCODE_GIT_IPC_HANDLE"
      set -ga update-environment " VSCODE_IPC_HOOK_CLI"
      set -ga update-environment " GIT_ASKPASS"

      # Renumber windows when one is closed
      set -g renumber-windows on

      # Longer display time for pane indicators
      set -g display-panes-time 2000

      # Status bar: catppuccin session indicator on the right
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_session}"
    '';
  };
}
