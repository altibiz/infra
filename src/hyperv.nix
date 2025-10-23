{
  lib,
  nixos-generators,
  disko,
  ...
}:

{
  branch.nixosModule.nixosModule = {
    imports = [
      nixos-generators.nixosModules.all-formats
      disko.nixosModules.disko
    ];

    disko.devices = {
      disk = {
        main = {
          device = "/dev/sda";
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "500M";
                label = "nixos-boot";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                label = "nixos-root";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };

    fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/nixos-root";
    fileSystems."/boot".device = lib.mkForce "/dev/disk/by-partlabel/nixos-boot";

    virtualisation.vmVariant.virtualisation.diskSize = 128 * 1024;
    virtualisation.vmVariant.virtualisation.memorySize = 2 * 1024;

    swapDevices = [
      {
        device = "/swapfile";
        size = 2048;
      }
    ];

    boot.loader = {
      grub.enable = false;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    boot.growPartition = true;

    virtualisation.hypervGuest.enable = true;
  };
}
