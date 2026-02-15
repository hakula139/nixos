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
