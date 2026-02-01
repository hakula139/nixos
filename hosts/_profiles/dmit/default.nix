{
  modulesPath,
  lib,
  ...
}:

# ==============================================================================
# DMIT Hardware Profile
# ==============================================================================
# This module contains shared boot loader, hardware, and disk configuration
# for all DMIT instances. Import this from your instance-specific host
# configuration.
# ==============================================================================

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../../modules/nixos
    ../disk-config.nix
  ];

  # ============================================================================
  # Boot Loader & Hardware
  # ============================================================================
  boot.loader.grub = {
    enable = true;
    devices = lib.mkForce [ "/dev/vda" ];
    configurationLimit = lib.mkDefault 5;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 2048;
    }
  ];

  services.qemuGuest.enable = true;
}
