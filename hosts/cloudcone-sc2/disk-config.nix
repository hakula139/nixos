{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "table";
          format = "msdos";
          partitions = [
            {
              name = "root";
              start = "1M";
              end = "100%";
              bootable = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [
                  "-O"
                  "^64bit,^metadata_csum"
                ];
              };
            }
          ];
        };
      };
    };
  };
}
