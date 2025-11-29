{ lib, pkgs, ... }:

{
  imports = [
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = false;
    mirroredBoots = lib.mkForce [
      {
        devices = [ "/dev/vda" ];
        path = "/boot";
      }
    ];
  };

  networking = {
    hostName = "hakula";
    domain = "xyz";
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 35060 ];
    };
  };

  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.hakula = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqd9HS6uF0h0mXMbIwCv9yrkvvdl3o1wUgQWVkjKuiJ"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    ports = [ 35060 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqd9HS6uF0h0mXMbIwCv9yrkvvdl3o1wUgQWVkjKuiJ"
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  system.stateVersion = "25.05";
}
