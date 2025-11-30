{ pkgs, ... }:

{
  # ============================================================================
  # Core System Configuration
  # ============================================================================
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # ============================================================================
  # Networking
  # ============================================================================
  networking = {
    domain = "hakula.xyz";
    firewall.enable = true;
  };

  # ============================================================================
  # Users & Security
  # ============================================================================
  users.users.hakula = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqd9HS6uF0h0mXMbIwCv9yrkvvdl3o1wUgQWVkjKuiJ"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqd9HS6uF0h0mXMbIwCv9yrkvvdl3o1wUgQWVkjKuiJ"
  ];

  security.sudo.wheelNeedsPassword = false;

  # ============================================================================
  # Services
  # ============================================================================
  services.openssh = {
    enable = true;
    ports = [ 35060 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # ============================================================================
  # Programs & Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  # Enable nix-ld for running unpatched binaries (e.g. VS Code Server, Cursor)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    openssl
    curl
    glib
    util-linux
    glibc
    icu
    libunwind
    libuuid
    libsecret
    libkrb5
  ];
}
