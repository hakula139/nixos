{ hostName, ... }:

{
  imports = [
    ../_profiles/tencent-lighthouse
  ];

  # ============================================================================
  # Networking
  # ============================================================================
  networking = {
    inherit hostName;
    useDHCP = true;
  };

  # ============================================================================
  # Services
  # ============================================================================
  hakula.services.cachix.enable = true;
  hakula.services.netdata.enable = true;
  hakula.services.nginx.enable = true;
  hakula.services.openssh = {
    enable = true;
    ports = [ 35060 ];
  };
  hakula.services.xray = {
    enable = true;
    ws.enable = true;
  };

  # ============================================================================
  # System State
  # ============================================================================
  system.stateVersion = "25.11";
}
