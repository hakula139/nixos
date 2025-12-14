{
  cachixCacheName,
  cachixPublicKey,
}:
let
  cachixCacheUrl = "https://${cachixCacheName}.cachix.org";
in
{
  substituters = [
    "https://cache.nixos.org"
    cachixCacheUrl
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    cachixPublicKey
  ];
}
